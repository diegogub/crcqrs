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

macro define_commands(cmd_handler,agg,*cmds)
  class {{cmd_handler}} < Crcqrs::CmdHandler
    def initialize()
      {% for  cmd, index in cmds%}
        commands << {{ cmd[:cmd].stringify }}
        events << {{ cmd[:event].stringify }}
      {% end %}
    end

  end

  {% for  c, index in cmds%}
    cmd({{cmd_handler}},{{c[:cmd]}})
  {% end %}

  cmd_emit({{cmd_handler}},{{*cmds}})
  event_emit({{agg}},{{*cmds}})

  {% for  c, index in cmds%}
    def_event({{agg}},{{c[:event]}},{{c[:prop]}})
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
macro cmd(cmd_handler,cmd)
  class {{cmd}} < Crcqrs::Cmd
    def name
      {{cmd.stringify}}
    end

    def event
      {{cmd.stringify}}
    end
  end

  # Define default handler for command, should emit default event with cmd data
  class {{cmd_handler}} < Crcqrs::CmdHandler
    def handle(cmd : {{cmd}})
    end
  end
end


#define event
macro def_event(agg,name,prop)
  class {{name}} < Crcqrs::Event
    JSON.mapping({{prop}})
  end

  class {{agg}} < Crcqrs::Aggregate
    def apply(id : String, version : Int64, event : {{name}})
      raise Exception.new("Event is not implemented")
    end
  end

end

macro impl_event(agg,name,&block)
  class {{agg}} < Crcqrs::Aggregate
    def apply(id : String, version : Int64, event : {{name}})
      {{ yield(block) }}
      inc_version(version)
    end
  end
end
