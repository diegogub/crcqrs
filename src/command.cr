require "json"

module Crcqrs
  abstract class Command
    @agg_id : String
    @data : JSON::Any
    @ts : Time

    def initialize(agg_id : String, data : String)
      @agg_id = id
      @data = JSON.parse(data)
      @ts = Time.utc_now
    end

    abstract def name : String
  end
end

macro commands(agg,*commands)
  {% for c in commands %}
    module Crcqrs
      class {{c}} < Crcqrs::Command
        def name
          {{c.stringify}}
        end
      end

      class {{agg}} < Crcqrs::Aggregate
        def handle(cmd : {{c}}) : Crcqrs::Event
        end
      end
    end
  {% end %}

  def map_command(agg_id : String, name : String,data : String) : Crcqrs::Command
  end
end
