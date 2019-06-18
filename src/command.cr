require "json"

module Crcqrs
  abstract class Command
    abstract def name : String
  end

  alias CommandError  = String
  alias CommandResult = Event | CommandError
end

