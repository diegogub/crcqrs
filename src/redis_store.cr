require "redis"

module Crcqrs
    class RedisStore < Store
        @rconn : Redis::PooledClient

        def initialize(@host = "localhost",@port = 6379)
            @rconn = Redis::PooledClient.new(host = @host ,port = @port)
        end

        def init
        end

        def save(stream : String, event : Event, create = false, lock = -1) : (Int64 | Crcqrs::StoreError)
            -1_i64
        end

        # replay aggregate from store
        def get_events(agg : AggregateRoot, stream : String, from : Int64) : (Iterator(Crcqrs::Event) | Crcqrs::StoreError)
            Crcqrs::StoreError::MissCache
        end

        def stream_exist(stream : String) : Bool
            false
        end

        # cache aggregate state on N version
        def cache(stream : String, agg : Aggregate)
        end

        # try to load aggregate from cache
        def hit_cache(stream : String) : (Crcqrs::CacheValue | Crcqrs::StoreError)
            Crcqrs::StoreError::MissCache
        end

        # correlative version of store, all events
        def correlative_version : Int64
            -1_i64
        end

        def get_events_correlative(from : Int64) : (Iterator(Crcqrs::RawEvent) | Crcqrs::StoreError)
            Crcqrs::StoreError::Failed
        end
    end
end
