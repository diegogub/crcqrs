module Crcqrs

  abstract class Store
    # saves event into store
    abstract def save(stream : String, event : Event)

    # checks if aggregate exist
    abstract def exist(prefix, agg_id : String) : Bool

    # replay aggregate from store
    abstract def replay(state : Crcqrs::Aggregate, snapshot = false)
  end
end
