require "../*"

module Crcqrs
  class MemoryStore < Crcqrs::Store
    @table : Hash(String,Array(Crcqrs::Event))

    def initialize()
      @table = Hash(String,Array(Crcqrs::Event)).new()
    end

  end
end
