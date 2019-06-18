require "./spec_helper"
require "json"


app = Crcqrs::App.new("banking test app","ba")


class Accounts < Crcqrs::AggregateRoot
    def name 
        "account"
    end

    def prefix 
        "acc"
    end

    def handle_command(agg_id : String , cmd : CreateAccount) : CommandResult
        "failed to create account"
    end
end

class CreateAccount < Crcqrs::Command
    JSON.mapping({
        id: String,
        balance: Int64
    })

    def name
        "CreateAccount"
    end

end

account_root = Accounts.new

app.add_aggregate(account_root)

cmd = CreateAccount.from_json(%({ "id" : "testing", "balance" : 10012}))
puts cmd.name
puts cmd.id
puts cmd.balance

puts account_root.handle_command(cmd)
