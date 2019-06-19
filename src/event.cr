require "ulid"

module Crcqrs
  abstract class Event
    property version 
    property id = ULID.generate
    property type = ""

    @version : Int64 = -1

    abstract def type : String
  end
end
