require "json"
require "time"

module Crcqrs
  # Cmd represent a event of will from the user to change state
  # The Cmd acts over one specific aggregate root
  abstract class Cmd
    getter name : String
    # cmd timestamp
    getter timestamp : Time
    # name of default event type to emit, with data
    getter default_event_type : String
    # data of cmd
    getter data : JSON::Any

    def initialize(data : String)
      @timestamp = Time.utc_now
      @data = JSON.parse(data)
    end

    # define name of cmd
    abstract def name : String
  end
end
