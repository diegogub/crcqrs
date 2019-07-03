module Crcqrs
  class App
    property store

    def initialize(@name, @prefix)
      @store = MemoryStore.new
    end

    # app name
    @name : String

    # general app prefix for streams created
    @prefix : String

    @aggregates : Hash(String, AggregateRoot) = Hash(String, AggregateRoot).new

    # store bucket, defaults to memory store
    @store : Store

    def init(store = MemoryStore.new)
      @store = store
      @store.init
    end

    def store
      @store
    end

    def add_aggregate(agg : AggregateRoot)
      @aggregates[agg.name] = agg
    end

    def build_stream(root : AggregateRoot, agg : Aggregate) : String
      "#{@name}|#{root.name}|#{agg.id}"
    end

    # rebuild_aggregate, rebuilds aggregate from past events
    def rebuild_aggregate(aggregate_root : AggregateRoot, stream : String, agg : Aggregate, use_cache : Bool) : Aggregate
      version_start = -1_i64

      if use_cache
        # try to hit cache
        cache_hit = @store.hit_cache(stream)
        case cache_hit
        when Crcqrs::CacheValue
          version_start = cache_hit.version + 1
          agg = aggregate_root.from_json(agg.id, cache_hit.data)
        else
          puts "miss"
        end
      end

      resp = @store.get_events(aggregate_root, stream, version_start)
      case resp
      when StoreError::NotFound
      when StoreError::Failed
        raise Exception.new("Failed to generate state from store")
      when StoreError
      else
        count = 0
        resp.each do |e|
          count = count + 1
          agg.apply(e)
          agg.set_version(e.version)
        end
      end

      if use_cache
        @store.cache(stream, agg)
      end

      agg
    end

    # f(cmd) -> event
    # Execute, executes command into system, using debug gets more verbose
    #  - debug : more verbose execution
    #  - mock : does not save event into eventstore
    #  - log  : logs command into eventstore
    #  - current_version : to check concurrency issues
    def execute(agg_name : String, agg_id : String, cmd : Command, current_version = -1, debug = false, mock = false) : (Crcqrs::Aggregate | String)
      begin
        cmd_validators = @aggregates[agg_name].validators

        agg_root = @aggregates[agg_name]
        agg = agg_root.new(agg_id)

        begin
          stream = build_stream(agg_root, agg)
          if debug
            puts "[#LOG] saving into:" + stream
          end

          if cmd.create
            if @store.stream_exist(stream)
              return "Aggregate already exist, failed to execute command: " + cmd.name
            end
          else
            if cmd.exist && !@store.stream_exist(stream)
              return "Aggregate does not exist, failed to execute command: " + cmd.name
            end
          end

          agg = rebuild_aggregate(agg_root, stream, agg, true)
        rescue e
          return "Failed to rebuild aggregate: " + e.message.as(String)
        end

        if cmd_validators.has_key?(cmd.name)
          cmd_validators[cmd.name].each do |val|
            if debug
              puts "[#LOG] Executing validator to command: " + val.name
            end

            res = val.validate(cmd)
            case res
            when CommandError
              return res
            end
          end
        end

        # handle command
        cmd_result = agg_root.handle_command(agg, cmd)
        case cmd_result
        when Event
          if mock
            puts "[#MOCK] Not saving into store, command validated"
          else
            store_resp = @store.save(stream, cmd_result)
            case store_resp
            when StoreError
              return "Failed to save event into store"
            else
              cmd_result
            end
          end
        else
          if debug
            puts "[#Error] Failed to execute command " + cmd.name
          end
        end

        agg
      rescue e
        puts e

        "Failed to execute command"
      end
    end
  end

  class Context
  end
end
