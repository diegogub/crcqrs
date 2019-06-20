require "json"

module Crcqrs
  alias CommandError = String
  alias CommandResult = Event | CommandError

  abstract class Command
    abstract def name : String
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

  macro define_command(name, properties)
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
  end
end
