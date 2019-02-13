module Crcqrs
  abstract class Event
    property id : String
    property type : String
    property stream : String
  end
end
