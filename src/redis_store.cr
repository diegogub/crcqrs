require "redis"

module Crcqrs
  class RedisEvent < Event
    JSON.mapping(
      id: String,
      type: {type: String, default: "", key: "t"},
      version: {type: Int64, default: -1_i64, key: "v"},
      data: {type: JSON::Any, default: JSON.parse("{}"), key: "d"}
    )

    @type : String = ""
    @version = -1_i64
    @data : JSON::Any = JSON.parse("{}")

    def initialize(e : Event)
      @type = e.type
      @data = JSON.parse(e.to_json)
    end
  end

  class RedisStore < Store
    @rconn : Redis::PooledClient

    def initialize(@host = "localhost", @port = 6379)
      @rconn = Redis::PooledClient.new(host = @host, port = @port)
    end

    def init
      # @rconn.set("app","foo")
    end

    def version(stream : String) : (Int64 | Crcqrs::StoreError)
      total = @rconn.llen("s:" + stream)
      case total
      when Nil
        StoreError::NotFound
      else
        if total > 0
          return total.to_i64 - 1
        else
          StoreError::NotFound
        end
      end
    end

    def save(stream : String, event : Event, create = false, lock = -1) : (Int64 | Crcqrs::StoreError)
      begin
        version = Redis::Future.new
        responses = @rconn.multi do |multi|
          store_event = RedisEvent.new(event)
          multi.hset("es", event.id, store_event.to_json)
          multi.rpush("s:" + stream, event.id)
          multi.rpush("c", event.id)
          version = multi.llen("s:" + stream)
        end

        version.value.as(Int64)
      rescue
        Crcqrs::StoreError::Failed
      end
    end

    def get_event(agg : AggregateRoot, id : String) : (Event | StoreError)
      j = @rconn.hget("es", id)
      begin
        r_event = RedisEvent.from_json(j.as(String))
        return r_event
      rescue
        StoreError::EventNotFound
      end
    end

    # replay aggregate from store
    def get_events(agg : AggregateRoot, stream : String, from : Int64) : (StreamCursor | Crcqrs::StoreError)
      c = StreamCursor.new
      batch_size = 100
      spawn do
        total = @rconn.llen("s:" + stream)
        pages = (total / batch_size).round + 1
        to = from + batch_size
        event = 0

        if from == -1
          version = from + 1
        else
          version = from
        end

        (0..pages).each do |p|
          r_list = @rconn.lrange("s:" + stream, from, to + 1)
          r_list.each do |e|
            j = @rconn.hget("es", e)
            begin
              r_event = RedisEvent.from_json(j.as(String))
              event = agg.gen_event(r_event.type, r_event.data.to_json)
              event.version = version.to_i64
              c.channel.send event
              version = version + 1
            rescue e
              version = version - 1
              puts "failed"
            end
          end
          from = to + 1
          to = from + batch_size
        end
        while true
          if c.channel.empty?
            c.channel.close
            break
          end
        end
      end

      c
    end

    def stream_exist(stream : String) : Bool
      @rconn.llen("s:" + stream) > 0
    end

    # cache aggregate state on N version
    def cache(stream : String, agg : Aggregate)
      puts ">"
      puts agg.version
      begin
        cache_val = CacheValue.new
        cache_val.data = agg.to_json
        cache_val.version = agg.version
        @rconn.set("ss:" + stream, cache_val.to_json)
      rescue
      end
    end

    # try to load aggregate from cache
    def hit_cache(stream : String) : (Crcqrs::CacheValue | Crcqrs::StoreError)
      begin
        res = @rconn.get("ss:" + stream)
        case res
        when String
          CacheValue.from_json(res)
        else
          Crcqrs::StoreError::MissCache
        end
      rescue e
        Crcqrs::StoreError::MissCache
      end
    end

    # correlative version of store, all events
    def correlative_version : Int64
      @rconn.llen("c")
    end

    def projection(id : String, version : Int64, error : String)
      # TODO
    end

    def get_projection(id : String) : ProjectionStatus
      ProjectionStatus.new
    end

    def list_projections : Array(ProjectionStatus)
      Array(ProjectionStatus).new
    end

    def get_events_correlative(from : Int64) : (Iterator(Crcqrs::RawEvent) | Crcqrs::StoreError)
      Crcqrs::StoreError::Failed
    end
  end
end
