module Crcqrs

  class MemoryStore < Store
    @streams : Hash(String, Array(Event))

    def initialize
      @streams = Hash(String, Array(Event)).new
    end

    def save(stream : String, event : Event)
    end

    # checks if aggregate exist
    def exist(stream : String) : Bool
    end

    # replay aggregate from store
    def replay(state : Crcqrs::Aggregate, snapshot = false)
    end
  end
end
