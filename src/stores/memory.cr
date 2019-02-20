require "../*"

module Crcqrs
  class MemoryStore < Crcqrs::Store
    @table : Hash(String, Array(Crcqrs::Event))

    def initialize
      @table = Hash(String, Array(Crcqrs::Event)).new
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
