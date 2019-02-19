require "json"

macro define_aggregate(name,prefix,prop)
  class {{name}} < Crcqrs::Aggregate
    JSON.mapping({{prop}})

    def prefix
      {{prefix.stringify}}
    end
  end
end

macro is_valid?(name,&block)
  class {{name}} < Crcqrs::Aggregate
    def valid? : Bool
      {{ yield(block) }}
    end
  end
end

macro define_commands(cmd_handler,*cmds)
  class {{cmd_handler}} < Crcqrs::CmdHandler
    def initialize()
      {% for  cmd, index in cmds%}
        commands[{{cmd[:cmd].stringify}}] = {{ cmd[:agg] }}.from_json("{}")
        events << {{ cmd[:event].stringify }}
      {% end %}
    end

    {% for  cmd, index in cmds%}
      def self.emit_agg(cmd : {{cmd[:cmd]}},id : String = "") : Crcqrs::Aggregate
        agg = {{cmd[:agg]}}.from_json("{}")
        agg.id = id
        return agg
      end
    {% end %}

  end

  {% for  c, index in cmds%}
    cmd({{cmd_handler}},{{c[:cmd]}},{{c[:event]}})
  {% end %}

  cmd_emit({{cmd_handler}},{{*cmds}})

  {% for  c, index in cmds%}
    event_emit({{c[:agg]}},{{*cmds}})
  {% end %}

  {% for  c, index in cmds%}
    def_event({{c[:agg]}},{{c[:event]}},{{ c[:create]}}, {{c[:prop]}})
  {% end %}
end

macro event_emit(agg,*cmds)
  class {{agg}} < Crcqrs::Aggregate
    def self.event(name : String,data : String) : Crcqrs::Event
      {%  begin %}
        case name
          {% for  cmd, index in cmds %}
          when "{{cmd[:event]}}"
            e = {{cmd[:event]}}.from_json(data)
            return e
          {% end %}
        else
          raise Exception.new("Invalid event, it's not registed: #{name}")
        end
      {% end %}
    end
  end
end

macro cmd_emit(cmd_handler,*cmds)
  class {{cmd_handler}} < Crcqrs::CmdHandler
    def self.cmd_factory(name : String, agg_id : String, data : String) : Crcqrs::Cmd
      {%  begin %}
        case name
          {% for  cmd, index in cmds %}
          when "{{cmd[:cmd]}}"
            c = {{cmd[:cmd]}}.new(agg_id,data)
            return c
          {% end %}
        else
          raise Exception.new("Invalid command, does not exist: #{name}")
        end
      {% end %}
    end

  end
end


# define command for determinated command handler
macro cmd(cmd_handler,cmd,event)
  class {{cmd}} < Crcqrs::Cmd
    def name
      {{cmd.stringify}}
    end

    def event
      {{event.stringify}}
    end
  end

  # Define default handler for command, should emit default event with cmd data
  class {{cmd_handler}} < Crcqrs::CmdHandler
    def handle(cmd : {{cmd}}) : Crcqrs::Event
      typeof(@commands[cmd.name]).event(cmd.event,cmd.data.to_json)
    end
  end
end


#define event
macro def_event(agg,name,create,prop)
  class {{name}} < Crcqrs::Event
    JSON.mapping({{prop}})

    def type
      {{name.stringify}}
    end

    def create
      {{create}}
    end
  end

  class {{agg}} < Crcqrs::Aggregate
    def apply(store : Crcqrs::Store, replay : Bool, version : Int64, event : {{name}})
      raise Exception.new("Event is not implemented")
    end
  end

end

macro impl_event(agg,name,&block)
  class {{agg}} < Crcqrs::Aggregate
    def apply(store : Crcqrs::Store, replay : Bool, version : Int64, event : {{name}})
      {{ yield(block) }}
      inc_version(version)
    end
  end
end
