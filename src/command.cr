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

macro commands(*commands)
  {% for c in commands %}
    class {{c}} < Crcqrs::Command
      def name
        {{c.stringify}}
      end
    end
  {% end %}
end
