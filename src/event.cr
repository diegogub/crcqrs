module Crcqrs
  abstract class Event
    abstract def id : String
    abstract def type : String
    abstract def valid : Bool
  end
end
