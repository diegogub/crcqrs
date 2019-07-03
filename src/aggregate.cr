require "ulid"

module Crcqrs
  # AggregateRoot is a type of entity, grouped by one prefix
  # A AggregateRoot must handle command and return event or error: AR(Command) -> Event|Error
  alias ConflictError = String

  abstract class AggregateRoot
    abstract def new(id : String) : Aggregate

    abstract def name : String
    abstract def prefix : String

    # validators for each command, could be from auth to check aggregates IDs
    abstract def validators : Hash(String, Array(Crcqrs::CommandValidator))

    abstract def conflict(type : String, events : Array(String)) : (ConflictError | Nil)

    # process event before saving
    @event_process : Array(Event -> Event) = Array(Event -> Event).new

    def handle_command(state : Crcqrs::Aggregate, cmd : Crcqrs::Command) : CommandResult
      raise Exception.new(cmd.name + " must be implemented")
    end
  end

  # Aggregate represents one entity with state
  abstract class Aggregate
    abstract def id : String
    abstract def version : Int64

    @version : Int64 = -1_i64

    # Apply should be implemented for each event
    def set_version(version : Int64)
      if version < @version
        raise Exception.new("Invalid version to set to aggregate")
      else
        @version = version.as(Int64)
      end
    end

    # execute after rebuild of aggregate
    def rebuild_hook
    end
  end

  # aggregate_root creates whole aggregate root
  macro aggregate_root(t, name, prefix, aggregate_type, aggregate_prop, *events)
      ## defines aggregate root
      class {{t}} < Crcqrs::AggregateRoot
          def name
              {{name}}
          end

          def new(id : String) : {{aggregate_type}}
              {{aggregate_type}}.new id
          end

          def from_json(id : String, data : String) : {{aggregate_type}}
              agg ={{aggregate_type}}.from_json(data)
              agg.id = id
              agg
          end

          def prefix
              {{prefix}}
          end
          def validators() : Hash(String,Array(Crcqrs::CommandValidator))
              Hash(String,Array(Crcqrs::CommandValidator)).new
          end

          def conflict(type : String, events : Array(String)) : (ConflictError | Nil)
              Nil
          end

          Crcqrs.define_event_factory({{*events}})
      end

      class {{aggregate_type}} < Crcqrs::Aggregate
          property id
          property version

          JSON.mapping({{aggregate_prop}})
          def id
              @id
          end

          @id : String = ""

          def initialize(@id)
              {% for key, value in aggregate_prop %}
                  @{{key}} = {{value[:default]}}
              {% end %}
          end

          def version
              @version
          end

          def apply(event : Crcqrs::Event)
              {% begin %}
                  case event
                      {% for e in events %}
                      when {{e}}
                          puts {{e}}
                          self.apply(event)
                      {% end %}
                  end
              {% end %}
          end
      end
  end

  macro apply_event(agg, event, &block)
      class {{agg}} < Crcqrs::Aggregate

          def apply(event : {{event}})
            {{ yield(block) }}
          end
      end
  end
end
