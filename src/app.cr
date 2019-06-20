module Crcqrs
  class App
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

    def add_aggregate(agg : AggregateRoot)
      @aggregates[agg.name] = agg
    end

    def build_stream(root : AggregateRoot, agg : Aggregate) : String
      "#{@name}|#{root.name}|#{agg.id}"
    end

    def rebuild_aggregate(aggregate_root : AggregateRoot, stream : String, agg : Aggregate) : Aggregate
      resp = @store.get_events(aggregate_root, stream, -1)
      case resp
      when StoreError::NotFound
      when StoreError::Failed
        puts resp
        raise Exception.new("Failed to generate state from store")
      when StoreError
      else
        resp.each do |e|
          agg.apply(e)
        end
      end

      agg
    end

    # Execute, executes command into system, using debug gets more verbose
    #  - debug : more verbose execution
    #  - mock : does not save event into eventstore
    #  - log  : logs command into eventstore
    def execute(agg_name : String, agg_id : String, cmd : Command, debug = false, mock = false, log = false) : CommandResult
      begin
        cmd_validators = @aggregates[agg_name].validators

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

        agg_root = @aggregates[agg_name]
        agg = agg_root.new(agg_id)
        begin
          stream = build_stream(agg_root, agg)
          agg = rebuild_aggregate(agg_root, stream, agg)
        rescue e
          return "Failed to rebuild aggregate: " + e.message.as(String)
        end

        # handle command
        cmd_result = agg_root.handle_command(agg, cmd)
        case cmd_result
        when Event
          # Store event into store
        else
          if debug
            puts "[#Error] Failed to execute command: " + cmd_result
          end
        end
        cmd_result
      rescue e
        puts e

        "Failed to execute command"
      end
    end
  end

  class Context
  end
end
