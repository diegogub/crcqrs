require "ulid"

module Crcqrs

  # Aggregate represents one entity with state
  abstract class Aggregate 
      abstract def id : String
      abstract def version : Int64
  end

  # AggregateRoot is a type of entity, grouped by one prefix
  # A AggregateRoot must handle command and return event or error: AR(Command) -> Event|Error
  abstract class AggregateRoot
    abstract def name : String
    abstract def prefix : String

    def handle_command(agg_id : String, cmd : Command) : CommandResult
        raise Exception.new(cmd.name + " must be implemented")
    end
  end

end
