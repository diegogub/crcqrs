module Crcqrs
  class MemoryStore < Store
    @mutex : Mutex = Mutex.new
    @initialized : Bool = false
    @streams : Hash(String, Array(Int64)) = Hash(String, Array(Int64)).new
    @events : Array(Event) = Array(Event).new
    @cache : Hash(String,Crcqrs::CacheValue) =  Hash(String,Crcqrs::CacheValue).new

    def init
      @initialize = true
      @streams = Hash(String, Array(Int64)).new
      @events = Array(Event).new
      @cache = Hash(String,Crcqrs::CacheValue).new
    end


    def hit_cache(stream : String) : (Crcqrs::CacheValue | StoreError)
        begin
            @cache[stream]
        rescue
            Crcqrs::StoreError::MissCache
        end
    end

    def cache(stream : String, agg : Aggregate)
        val = Crcqrs::CacheValue.new
        val.version = agg.version
        val.data = agg.to_json
        @cache[stream] = val
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
        event.version = version + 1
        @events << event
        @streams[stream] << @events.size.to_i64

        version
      ensure
        @mutex.unlock
      end
    end

    def get_events(agg_root : AggregateRoot, stream : String, from : Int64) : (Iterator(Event) | StoreError)
      events = Array(Event).new
      if !self.stream_exist(stream)
        StoreError::NotFound
      end

      begin
        @mutex.lock
        if from > 0 
            @streams[stream].skip(from).each do |v|
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

      events.each
    end

    def stream_exist(stream : String) : Bool
      @streams.has_key?(stream)
    end
  end
end
