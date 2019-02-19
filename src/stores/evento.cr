require "evento"
require "json"

module Crcqrs
  class StoreEvent
    property t, d

    JSON.mapping(
      t: String,
      d: JSON::Any
    )

    def initialize(event : Event)
      @t = event.type
      @d = JSON.parse(event.to_json)
    end
  end

  class EventoStore < Crcqrs::Store
    @cli : Evento::Client

    def initialize(address : String,port : Int32)
      @cli = Evento::Client.new(address,port)
      puts "Checking store version:#{@cli.store_version()}"
    end

    def save(agg : Crcqrs::Aggregate, event : Event) : Int64 | Crcqrs::StoreError
      e = StoreEvent.new(event)
      begin
        if event.create
          @cli.store(agg.stream,e.to_json, id = "", create = true)
        else
          @cli.store(agg.stream,e.to_json, id = "", create = false)
        end
      rescue Evento::LockError
        StoreError::Lock
      rescue Evento::StreamNotCreated
        StoreError::Exist
      rescue
        StoreError::Failed
      end
    end

    def exist(stream : String) : Bool
      begin
        version = @cli.version(stream)
        version > -1
      rescue
        false
      end
    end

    def replay(state : Crcqrs::Aggregate, snapshot = false)
      puts "replaying ..#{state.stream}"
      ch = @cli.read state.stream
      while true
        event = ch.receive?
        case event
        when nil
          puts "breaking.."
          break
        else
          sevent = StoreEvent.from_json(event[:data])
          state.apply(self, true, event[:version],typeof(state).event(sevent.t,sevent.d.to_json))
          puts state.to_json
        end
      end
    end

  end
end
