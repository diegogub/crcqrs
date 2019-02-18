require "json"
require "ulid"
require "time"


module Crcqrs
  abstract class CmdHandler
    property commands
    property events
    @commands : Array(String) = Array(String).new()
    @events : Array(String) = Array(String).new()
  end

  # Handle all commmands, has access to event store, indexes and external services

  # Cmd represent a event of will from the user to change state
  # The Cmd acts over one specific aggregate root
  abstract class Cmd
    # command id for logging?
    @id : String = ""
    # acting aggregate
    @agg_id : String = ""
    # current time
    @timestamp : Time = Time.utc_now
    # cmd data
    ## TODO rise issue with this, does not work
    ##@data : JSON::Any = JSON.parse("{}")
    #
    @data : JSON::Any

    property id
    property agg_id
    property timestamp : Time
    property data : JSON::Any

    def initialize()
      @data = JSON.parse("{}")
    end

    def initialize(@agg_id : String,data : String)
      @id = ULID.generate
      @timestamp = Time.utc_now
      if data == ""
        @data = JSON.parse("{}")
      else
        @data = JSON.parse(data)
      end
    end

    def to_json : JSON::Any
      @data
    end

    # define name of cmd
    abstract def name : String
    # event to emit from command
    abstract def event : String
  end
end
