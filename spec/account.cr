require "./spec_helper"
require "ulid"
require "json"

app = Crcqrs::App.new("banking test app", "ba")

class Accounts < Crcqrs::AggregateRoot
  def new(id : String) : Account
    account = Account.new id
    account
  end

  def name
    "account"
  end

  def prefix
    "acc"
  end

  Crcqrs.define_event_factory AccountCreated, AccountTested

  def validators : Hash(String, Array(Crcqrs::CommandValidator))
    vals = Hash(String, Array(Crcqrs::CommandValidator)).new
    vals["CreateAccount"] = Array(Crcqrs::CommandValidator).new

    return vals
  end

  def handle_command(agg_id : String, cmd : CreateAccount) : Crcqrs::CommandResult
    "failed to create account"
  end
end

Crcqrs.define_event_factory AccountCreated, AccountTested

class Account < Crcqrs::Aggregate
  property id : String = ""
  property version : Int64 = -1_i64

  def initialize(@id)
    @version = -1_i64
  end
end

Crcqrs.define_event AccountCreated, {balance: {type: Int64, default: 0_i64}}
Crcqrs.define_event AccountTested, {msg: {type: String, default: "-"}}

Crcqrs.define_command CreateAccount, {balance: {type: Int64, default: 0_i64}}

account_root = Accounts.new

app.add_aggregate(account_root)

cmd = CreateAccount.from_json(%({ "balance" : 10012}))
mem_store = Crcqrs::MemoryStore.new
mem_store.init

mem_store.save("testing", AccountCreated.from_json("{}"))

res = mem_store.get_events(account_root, "testing", 0)
case res
when Crcqrs::StoreError
  puts res
else
  puts typeof(res)
  res.each do |e|
    case e
    when AccountCreated
      puts ">>", e.id
      puts e.version
      puts e.balance
    end
  end
end

# execute command
puts app.execute(account_root.name, "testing", cmd, debug = true)

a = gen_event("AccountTested")
puts a.msg
puts typeof(a)
