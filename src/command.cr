require "json"

module Crcqrs
  alias CommandError  = String
  alias CommandResult = Event | CommandError

  abstract class Command
    abstract def name : String
  end

  # classes responsable to validate commands, reading repositories, indexes and data
  abstract class CommandValidator
      abstract def validate(cmd : Command) : (Nil | CommandError)
  end

end

