module Crcqrs
  class ProjectionStatus
    @id : String = ""
    @failed : Bool = false
    @error : String = ""
    @version : Int64 = -1_i64

    JSON.mapping(
      id: String,
      failed: Bool,
      error: String,
      version: Int64
    )

    def initialize
    end
  end

  abstract class Projection
    # current projection version
    @version : Int64 = -1_i64
    @id : String = ""
    @failed : Bool = false
    @error : String = ""

    def initialize(id : String, store : Store)
      # projection from store
      @id = id.downcase
      @store = store
    end

    def run
      # get current store version
      loop do
        current = @store.correlative_version
        projection = @store.get_projection(@id)

        @version = projection.version + 1

        if @version < current
          cursor = @store.get_events_correlative(@version)
          case cursor
          when StoreError
            puts "Failed to get event from store..sleeping"
            sleep 5
          else
            cursor.each do |e|
              err = handle_event(e)
              case err
              when String
                @version = e.version - 1
                @store.projection(@id, @version, err)
              else
                @version = e.version
                @store.projection(@id, @version, "")
              end
            end
          end
        end

        sleep 0.2
      end
    end

    abstract def handle_event(event : Event)
  end

  class MemoryProjection < Projection
    def handle_event(event : Event) : (Nil | String)
      puts event.to_json
    end
  end
end
