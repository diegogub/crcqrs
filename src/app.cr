
module Crcqrs
  class App
      # app name
      @name : String

      # general app prefix for streams created
      @prefix : String

      @aggregates : Hash(String,AggregateRoot) = Hash(String,AggregateRoot).new()

      # store bucket, defaults to memory store
      @store : Store 

      def initialize(@name,@prefix)
          @store = MemoryStore.new()
      end

      def init(store = MemoryStore.new())
          @store = store
          @store.init
      end

      def add_aggregate(agg : AggregateRoot)
          @aggregates[agg.name] = agg
      end

      # Execute, executes command into system, using debug gets more verbose
      #  - debug : more verbose execution
      #  - mock : does not save event into eventstore
      #  - log  : logs command into eventstore
      def execute(agg_name : String,agg_id : String ,cmd : Command, debug = false, mock = false, log = false) : CommandResult
          begin
              cmd_validators = @aggregates[agg_name].validators

              if cmd_validators.has_key?(cmd.name)
                  cmd_validators[cmd.name].each do |val|
                      res = val.validate(cmd)
                      case res
                      when CommandError
                          return res
                      end
                  end
              end

              cmd_result = @aggregates[agg_name].handle_command(agg_id,cmd)
              case cmd_result
                  when Event
                      # Store event into store
                  else
                      if debug
                          puts "[#Error] Failed to execute command: " + cmd_result
                      end
              end
              cmd_result
          rescue e
              puts e

              "Failed to execute command"
          end
      end
  end

  class Context
  end
end
