require "./stores/memory"

module Crcqrs
  enum StoreError
    NotFound
    Exist
    Lock
    Failed
    MissCache
  end

  alias StoreParams = {create: Bool, lock: Int64}

  class CacheValue
    property version
    property data

    @version : Int64 = -1_i64
    @data : String = "{}"
  end

  class StreamCursor
    include Iterator(Event)
    property channel

    @channel : Channel(Event) = Channel(Event).new(100)

    def next
      if @channel.closed?
        stop
      else
        begin
          @channel.receive
        rescue
          stop
        end
      end
    end
  end

  abstract class Store
    abstract def init
    # saves event into store
    abstract def save(stream : String, event : Event, create = false, lock = -1) : (Int64 | StoreError)

    # replay aggregate from store
    abstract def get_events(agg : AggregateRoot, stream : String, from : Int64) : (StreamCursor | StoreError)

    abstract def stream_exist(stream : String) : Bool

    # correlative version of store, all events
    abstract def correlative_version : Int64

    # get_events_correlative, streams events from all events
    abstract def get_events_correlative(from : Int64) : (StreamCursor | StoreError)

    # cache aggregate state on N version
    abstract def cache(stream : String, agg : Aggregate)

    # try to load aggregate from cache
    abstract def hit_cache(stream : String) : (CacheValue | StoreError)
  end
end
