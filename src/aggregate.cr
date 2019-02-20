require "ulid"

module Crcqrs
  abstract class Aggregate
    property id
    @version : Int64 = -1
    @id : String = ""

    def initialize(@id)
      @version = -1
    end

    # prefix of stream
    abstract def prefix : String

    # function to determinate current status is valid
    abstract def is_valid?

    def id
      if @id == ""
        @id = ULID.generate
      end

      @id
    end

    # defines stream for aggregate
    def stream : String
      "#{self.prefix}#{AGGREGATE_SEPARATOR}#{@id}"
    end

    # gets current stream version
    def version : Int64
      @version
    end

    def string : String
      self.stringify
    end

    def inc_version(v : Int64)
      if (@version + 1 == v)
        @version = v
      else
        raise Exception.new("Invalid event to apply, version mismatch")
      end
    end
  end
end

macro aggregate(name, prefix, properties, *events)
  class {{name}} < Crcqrs::Aggregate
    JSON.mapping({{properties}})

    def self.event(type : String, data : String) : Crcqrs::Event
      build_event(type,data)
    end

    def self.create(id : String = "") : {{name}}
      a = {{name}}.from_json("{}")
      a.id = id
      a.id
      return a
    end

    def prefix
      {{prefix.stringify}}
    end

    {% for e in events %}
      def apply(store : Crcqrs::Store, version : Int64, event : {{e}},replay : Bool = false) : Crcqrs::Aggregate
        raise Exception.new("Event is not implemented")
        self
      end
    {% end %}
  end
end

macro aggregate_valid?(name, &block)
  class {{name}} < Crcqrs::Aggregate
    def is_valid?
      {{ yield(block) }}
    end
  end
end

macro impl_event(agg, name, &block)
  class {{agg}} < Crcqrs::Aggregate
    def apply(context : Crcqrs::Context, store : Crcqrs::Store, version : Int64, event : {{e}},replay : Bool = false) : Crcqrs::Aggregate
      {{ yield(block) }}
      inc_version(version)
      return self
    end
  end
end
