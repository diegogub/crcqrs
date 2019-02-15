require "json"
require "time"

module Crcqrs
  # Handle all commmands, has access to event store, indexes and external services
  class CmdHandler
    # list of aggregates
    @aggregates : Hash(String, Crcqrs::Aggregate)
    # maps one command to one aggregate
    @commands : Hash(String, String)

    def initialize(aggregates : Array(Crcqrs::Aggregate))
      # init maps
      @aggregates = Hash(String, Aggregate).new
      @commands = Hash(String, String).new

      aggregates.each do |a|
      end
    end
  end

  # Cmd represent a event of will from the user to change state
  # The Cmd acts over one specific aggregate root
  abstract class Cmd
    # cmd timestamp
    getter timestamp : Time
    # data of cmd
    getter data : JSON::Any

    def initialize(data : String)
      @timestamp = Time.utc_now
      @data = JSON.parse(data)
    end

    def to_json : JSON::Any
      @data
    end

    # define name of cmd
    abstract def name : String
    abstract def default_event_type : String
  end
end
