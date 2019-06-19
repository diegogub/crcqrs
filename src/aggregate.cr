require "ulid"

module Crcqrs

  # Aggregate represents one entity with state
  abstract class Aggregate 
      abstract def id : String
      abstract def version : Int64

      def apply(ch : Event)
      end
      
      # execute after rebuild of aggregate
      def rebuild_hook()
      end
  end

  # AggregateRoot is a type of entity, grouped by one prefix
  # A AggregateRoot must handle command and return event or error: AR(Command) -> Event|Error
  abstract class AggregateRoot
    abstract def name : String
    abstract def prefix : String

    # validators for each command, could be from auth to check aggregates IDs
    abstract def validators : Hash(String,Array(CommandValidator))

    # process event before saving
    @event_process : Array(Event -> Event) = Array(Event -> Event).new

    def handle_command(state : Aggregate, cmd : Command) : CommandResult
        raise Exception.new(cmd.name + " must be implemented")
    end
  end

end
