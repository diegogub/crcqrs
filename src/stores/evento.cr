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

    def initialize(address : String, port : Int32, @dev = false)
      @cli = Evento::Client.new(address, port)
      if @dev
        puts "Initialized store with total version:#{@cli.store_version}"
      end
    end

    def save(agg : Crcqrs::Aggregate, event : Event) : Int64 | Crcqrs::StoreError
      e = StoreEvent.new(event)
      begin
        if event.create
          @cli.store(agg.stream, e.to_json, id = "", create = true)
        else
          @cli.store(agg.stream, e.to_json, id = "", create = false)
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

    def replay(state : Crcqrs::Aggregate, snapshot = false) : Crcqrs::Aggregate
      ch = @cli.read state.stream
      while true
        event = ch.receive?
        case event
        when nil
          break
        else
          sevent = StoreEvent.from_json(event[:data])
          if @dev
            puts "Event:"
            puts event.to_json
          end

          # empty context, we are replaying events
          state.apply(self, event[:version], typeof(state).event(sevent.t, sevent.d.to_json), true)
        end
      end

      return state
    end
  end
end
