require "./store"

module Crcqrs
  class MemoryStore < Store
    @mutex : Mutex = Mutex.new
    @initialized : Bool = false
    @streams : Hash(String, Array(Int64)) = Hash(String, Array(Int64)).new
    @events : Array(Event) = Array(Event).new
    @events_by_id : Hash(String, Int64) = Hash(String, Int64).new
    @cache : Hash(String, Crcqrs::CacheValue) = Hash(String, Crcqrs::CacheValue).new

    def init
      @initialize = true
      @streams = Hash(String, Array(Int64)).new
      @events = Array(Event).new
      @cache = Hash(String, Crcqrs::CacheValue).new
    end

    def hit_cache(stream : String) : (Crcqrs::CacheValue | StoreError)
      begin
        @cache[stream]
      rescue
        Crcqrs::StoreError::MissCache
      end
    end

    def get_event(agg : AggregateRoot, id : String) : (Event | StoreError)
      begin
        @events[@events_by_id[id]]
      rescue
        StoreError::EventNotFound
      end
    end

    def cache(stream : String, agg : Aggregate)
      val = Crcqrs::CacheValue.new
      val.version = agg.version
      val.data = agg.to_json
      @cache[stream] = val
    end

    def version(stream : String) : (Int64 | StoreError)
      begin
        version = @streams[stream].size.to_i64 - 1
        version
      rescue
        StoreError::NotFound
      end
    end

    def save(stream : String, event : Event, create = false, lock = -1) : (Int64 | StoreError)
      begin
        v = @streams[stream]
        if create
          StoreError::Exist
        end
      rescue
        @streams[stream] = Array(Int64).new
      end

      begin
        @mutex.lock
        version = @streams[stream].size.to_i64 - 1
        if lock >= 0
          if version != lock
            StoreError::Lock
          end
        end
        event.version = version + 1
        @events << event
        @streams[stream] << @events.size.to_i64
        @events_by_id[event.id] = @events.size.to_i64

        version
      ensure
        @mutex.unlock
      end
    end

    def get_events(agg_root : AggregateRoot, stream : String, from : Int64) : (StreamCursor | StoreError)
      events = Array(Event).new
      if !self.stream_exist(stream)
        StoreError::NotFound
      end

      begin
        @mutex.lock
        if from > 0
          @streams[stream].skip(from + 1).each do |v|
            events << @events[v - 1]
          end
        else
          @streams[stream].each do |v|
            events << @events[v - 1]
          end
        end
      rescue
        StoreError::Failed
      ensure
        @mutex.unlock
      end

      cursor = StreamCursor.new
      spawn do
        events.each do |e|
          cursor.channel.send e
        end
        begin
          cursor.channel.close
        rescue
        end
      end

      cursor
    end

    def stream_exist(stream : String) : Bool
      @streams.has_key?(stream)
    end

    def correlative_version : Int64
      @events.size.to_i64
    end

    def projection(id : String, version : Int64, error : String)
    end

    def get_projection(id : String) : ProjectionStatus
      ProjectionStatus.new
    end

    def list_projections : Array(ProjectionStatus)
      Array(ProjectionStatus).new
    end

    def get_events_correlative(from : Int64) : (Iterator(Event) | StoreError)
      @events.skip(from + 1).each
    end
  end
end
