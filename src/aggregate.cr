require "ulid"

module Crcqrs
  abstract class Aggregate
    @version : Int64 = -1
    @id : String = ""

    def initialize(@id)
      @version = -1
    end

    # prefix of stream
    abstract def prefix : String

    # function to determinate current status is valid
    abstract def valid? : Bool

    def id
      if @id == ""
        @id = ULID.generate
      end

      @id
    end

    # defines stream for aggregate
    def stream : String
      "#{@prefix}#{AGGREGATE_SEPARATOR}#{@id}"
    end

    # gets current stream version
    def version : Int64
      version
    end

    def string : String
      self.stringify
    end

    def inc_version(v : Int64)
      if (@version + 1 == v)
        @version = v
      else
        raise Exception.new("Invalid event to apply, version mismatch")
      end
    end
  end
end
