
module Crcqrs
  class App
      # app name
      @name : String

      # general app prefix for streams created
      @prefix : String

      @aggregates : Hash(String,AggregateRoot) = Hash(String,AggregateRoot).new()

      # store bucket, defaults to memory store
      @store : Store  = MemoryStore.new()

      def initialize(@name,@prefix)
      end

      def add_aggregate(agg : AggregateRoot)
          @aggregates[agg.name] = agg
      end

      # Execute, executes command into system, using degub gets more verbose
      #  - debug : more verbose execution
      #  - mock : does not save event into eventstore
      #  - log  : logs command into eventstore
      def execute(aggregate_name : String,cmd : Command, debug = false, mock = false, log = false) : CommandResult
      end
  end
end
