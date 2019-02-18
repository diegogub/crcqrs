require "evento"
require "json"

module Crcqrs
  class StoreEvent
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
      @cli.exist(stream)
    end

    def replay(state : Crcqrs::Aggregate, snapshot = false)
      puts "replaying ..#{state.stream}"
    end

  end
end
