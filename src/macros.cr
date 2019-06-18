

# TODO
# Must redefine all macros to make it clear
#
#macro define_aggregate(name, prefix, properties, *events)
#  class {{name}} < Crcqrs::Aggregate
#    JSON.mapping({{properties}})
#
#    def self.event(type : String, data : String) : Crcqrs::Event
#      build_event(type,data)
#    end
#
#    def self.create(id : String = "") : {{name}}
#      a = {{name}}.from_json("{}")
#      a.id = id
#      a.id
#      return a
#    end
#
#    def prefix
#      {{prefix.stringify}}
#    end
#
#    {% for e in events %}
#      def apply(store : Crcqrs::Store, version : Int64, event : {{e}},replay : Bool = false) : Crcqrs::Aggregate
#        raise Exception.new("Event is not implemented")
#        self
#      end
#    {% end %}
#  end
#end
#
#macro aggregate_valid?(name, &block)
#  class {{name}} < Crcqrs::Aggregate
#    def is_valid?
#      {{ yield(block) }}
#    end
#  end
#end
#
#macro impl_event(agg, name, &block)
#  class {{agg}} < Crcqrs::Aggregate
#    def apply(context : Crcqrs::Context, store : Crcqrs::Store, version : Int64, event : {{name}},replay : Bool = false) : Crcqrs::Aggregate
#      {{ yield(block) }}
#      inc_version(version)
#      return self
#    end
#  end
#end

#macro commands(agg,*commands)
#  {% for c in commands %}
#    module Crcqrs
#      class {{c}} < Crcqrs::Command
#        def name
#          {{c.stringify}}
#        end
#      end
#
#      class {{agg}} < Crcqrs::Aggregate
#        def handle(cmd : {{c}}) : Crcqrs::Event
#        end
#      end
#    end
#  {% end %}
#
#  def map_command(agg_id : String, name : String,data : String) : Crcqrs::Command
#  end
#end
