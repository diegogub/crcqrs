module Crcqrs
  abstract class Event
    abstract def type : String

    # property id : String
    # property type : String
    # property stream : String

    def transform : Crcqrs::Event
      self
    end

    def valid? : Bool
      true
    end
  end
end

# Define events, and efect factory function
macro events(*all)
  {% for e in all %}
  class {{e[0]}} < Crcqrs::Event
    JSON.mapping({{e[1]}})
    def type
      {{e[0].stringify}}
    end

    def create
      {{e[2]}}
    end


  end
  {% end %}

  # event factory
  def build_event(type : String,data : String = "{}") : Crcqrs::Event
    {% begin %}
      case type
        {% for event, index in all %}
        when "{{event[0]}}"
          e = {{event[0]}}.from_json(data)
          return e
        {% end %}
      else
        raise Exception.new("Invalid event, it's not registed: #{type}")
      end
    {% end %}
  end
end

macro event_valid?(event, &block)
  class {{event}}
    def valid?()
      {{ yield(block) }}
    end
  end
end

macro event_transform(event, &block)
  class {{event}}
    def transform() : Crcqrs::Event
      {{ yield(block) }}
      self
    end
  end
end
