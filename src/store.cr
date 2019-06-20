require "./stores/memory"

module Crcqrs
  enum StoreError
    NotFound
    Exist
    Lock
    Failed
  end

  alias StoreParams = {create: Bool, lock: Int64}

  abstract class Store
    abstract def init
    # saves event into store
    abstract def save(stream : String, event : Event, create = false, lock = -1) : (Int64 | StoreResult)

    # replay aggregate from store
    abstract def get_events(agg : AggregateRoot, stream : String, from : Int64) : (Iterator(Event) | StoreError)

    abstract def stream_exist(stream : String) : Bool
  end
end
