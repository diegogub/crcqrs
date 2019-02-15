require "ulid"

module Crcqrs
  abstract class Aggregate
    @version : Int64 = -1
    @id : String = ""

    def initialize(@id)
      @version = -1
    end

    abstract def prefix : String
    abstract def valid? : Bool

    def id
      if @id == ""
        @id = ULID.generate
      end

      @id
    end

    def stream : String
      "#{@prefix}#{AGGREGATE_SEPARATOR}#{@id}"
    end

    # gets current stream version
    def version() : Int64
      version
    end

    def string : String
      self.stringify
    end
  end
end
