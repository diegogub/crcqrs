module Crcqrs
  abstract class Aggregate
    property prefix : String
    property id : String
    property version : Int64

    def initialize(@id,@prefix)
        @version = -1
    end

    def stream : String
      "#{@prefix}#{AGGREGATE_SEPARATOR}#{@id}"
    end

    def string : String
        self.stringify
    end
  end
end
