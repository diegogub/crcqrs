require "./spec_helper"

Crcqrs.aggregate_root(Accounts, "account", "acc", Account, {balance: {type: Int64, default: 0_i64}, owner: {type: String, default: "-"}}, AccountCreated, MoneyDeposited)

Crcqrs.define_event AccountCreated, {balance: {type: Int64, default: 0_i64}}
Crcqrs.apply_event Account, AccountCreated do
  self.balance = event.balance
end

Crcqrs.define_command Accounts, CreateAccount, {balance: {type: Int64, default: 0_i64}} do
  if state.balance > 0
    return "Failed to create Account already exist"
  end

  event = AccountCreated.new
  event.balance = cmd.balance
  return event
end
Crcqrs.command_must_create_agg(CreateAccount)

Crcqrs.define_event MoneyDeposited, {amount: {type: Int64, default: 0_i64}}
Crcqrs.apply_event Account, MoneyDeposited do
  self.balance += event.amount
end

Crcqrs.define_command Accounts, DepositMoney, {amount: {type: Int64, default: 0_i64}} do
  if cmd.amount <= 0
    return "Invalid amount to deposit: " + cmd.amount.to_s
  end
  event = MoneyDeposited.new
  event.amount = cmd.amount
  return event
end

accounts = Accounts.new
app = Crcqrs::App.new("banking", "bk")

redis_store = Crcqrs::RedisStore.new
redis_store.init

pg_store = Crcqrs::PostgresStore.new "banking"
pg_store.init

app.init
app.store = pg_store
app.add_aggregate(accounts)

cmd = CreateAccount.from_json(%({ "balance" : 0}))
app.execute("account", "t4", cmd, debug = true)

(1..100).each do |i|
  # t = Time.now
  cmd2 = DepositMoney.from_json(%({ "amount" : 1}))
  puts app.execute("account", "t4", cmd2, debug = false).to_json
  # t2 = Time.now
  # puts t2 - t
end

acc = accounts.new "t4"
acc = app.rebuild_aggregate(accounts, "banking|account|t4", acc, true)
puts acc.to_json

puts ">>"
puts app.get_aggregate("account", "t4").to_json
puts ">>"
puts app.get_aggregate("account", "t49").to_json

e = app.get_event("account", "01DF5K13MEFF8BNA0MT3TVJF1Z")
case e
when Crcqrs::Event
  puts e.to_json
  puts e.version
  puts e.type
  puts e.id
end
