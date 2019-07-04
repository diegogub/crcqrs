require "ulid"

module Crcqrs
  abstract class Event
    property version
    property id = ULID.generate
    @version : Int64 = -1

    abstract def type : String
  end

  class RawEvent < Event
    JSON.mapping(
        id: String,
        type: String,
        version: Int64,
        data: JSON::Any
    )

    property data
    property type

    @type : String = ""
    @data : JSON::Any = JSON.parse("{}")

    def initialize
    end

    def type
      @type
    end
  end

  macro define_event(name, properties)
      class {{name}} < Crcqrs::Event
          JSON.mapping(
              {{properties}}
          )

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

          def type 
              return {{name.stringify}}
          end
      end
  end

  macro define_event_factory(*events)
     def gen_event(type : String,json : String) : {% begin %}({% for e in events %} {{e}} | {% end %} Nil) {% end %}
          {% begin %}
              case type 
                 {% for e in events %}
                 when {{e.stringify}}
                     return {{e}}.from_json(json).as({{e}})
                 {% end %}

                 else
                     raise Exception.new("Cannot generate event of type: " + type)
              end
          {% end %}
      end
  end
end
