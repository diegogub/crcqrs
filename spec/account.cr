require "./spec_helper"
require "ulid"
require "json"


app = Crcqrs::App.new("banking test app","ba")


class Accounts < Crcqrs::AggregateRoot
    def name 
        "account"
    end

    def prefix 
        "acc"
    end

    def validators() : Hash(String,Array(Crcqrs::CommandValidator))
        vals = Hash(String,Array(Crcqrs::CommandValidator)).new
        vals["CreateAccount"] = Array(Crcqrs::CommandValidator).new

        return vals
    end

    def handle_command(agg_id : String , cmd : CreateAccount) : Crcqrs::CommandResult
        "failed to create account"
    end
end

class CreateAccount < Crcqrs::Command
    JSON.mapping({
        balance: Int64
    })

    def name
        "CreateAccount"
    end

end

class AccountDeposited < Crcqrs::Event
    JSON.mapping({
        amount: Int64,
    })

    def type
        "AccountDeposited"
    end
end

class AccountCreated < Crcqrs::Event
    property balance
    @balance : Int64

    def initialize(@balance)
    end

    def type
        "AccountCreated"
    end

    def valid
        true
    end
end

account_root = Accounts.new

app.add_aggregate(account_root)

cmd = CreateAccount.from_json(%({ "balance" : 10012}))
puts cmd.name
puts cmd.balance

mem_store = Crcqrs::MemoryStore.new
mem_store.init

mem_store.save("testing",AccountCreated.new(600_i64),NamedTuple.new( create: false, lock: -1) )

res = mem_store.get_events("testing",0)
case res 
when Crcqrs::StoreError
    puts res
else
    puts typeof(res)
    res.each do |e|
        case e
        when AccountCreated
            puts ">>" ,e.id
            puts e.version
            puts e.balance
        when AccountDeposited
            puts ">>" ,e.id
            puts e.version
            puts e.amount
        end
    end
end

# execute command
puts app.execute(account_root.name,"testing",cmd, debug= true)
