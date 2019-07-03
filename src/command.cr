require "json"

module Crcqrs
  alias CommandError = String
  alias CommandResult = Event | CommandError

  abstract class Command
    abstract def name : String

    def create : Bool
      false
    end

    def exist : Bool
      true
    end
  end

  # classes responsable to validate commands, reading repositories, indexes and data
  abstract class CommandValidator
    abstract def name : String
    abstract def validate(cmd : Command) : (Nil | CommandError)
  end

  # # define validator
  macro command_validator(name, &block)
      class {{name}} < Crcqrs::CommandValidator
          def name
              {{name.stringify}}
          end

          def validate(cmd : Command) : (Nil | CommandError)
              yield(block)
          end
      end
  end

  macro command_must_create_agg(name)
      class {{name}} < Crcqrs::Command
          def create : Bool
              true
          end
      end
  end

  macro command_agg_no_exist(name)
      class {{name}} < Crcqrs::Command
          def exist: Bool
              false
          end
      end
  end

  macro define_command(aggregate, name, properties, &block)
      class {{name}} < Crcqrs::Command
          JSON.mapping(
              {{properties}}
          )

          def name
              return {{name.stringify}}
          end

          def initialize
              {% for key, value in properties %}
                  @{{key}} = {{value[:default]}}
              {% end %}
          end

          {% for key, value in properties %}
              def {{key}}
                @{{key}}
              end
          {% end %}
      end

      class {{aggregate}} < Crcqrs::AggregateRoot
          def handle_command(state : Crcqrs::Aggregate, cmd : {{name}}) : Crcqrs::CommandResult
              {{ yield(block) }}

              state
          end
      end
  end
end
