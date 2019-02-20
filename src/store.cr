module Crcqrs
  enum StoreError
    Exist
    Lock
    Failed
  end

  abstract class Store
    # saves event into store
    abstract def save(agg : Aggregate, event : Event, id = "", create = false, lock = Int64.new(-1)) : (Int64 | StoreResult)

    # checks if aggregate exist
    abstract def exist(stream : String) : Bool

    # replay aggregate from store
    abstract def replay(state : Crcqrs::Aggregate, snapshot = false)
  end
end
