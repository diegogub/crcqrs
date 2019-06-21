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

  event
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
app.init
app.add_aggregate(accounts)

cmd = CreateAccount.from_json(%({ "balance" : 0}))
puts app.execute("account", "testing", cmd, debug = true)

(1..10_000).each do |i|
  cmd2 = DepositMoney.from_json(%({ "amount" : 1}))
  app.execute("account", "testing", cmd2, debug = false)
end

cmd2 = DepositMoney.from_json(%({ "amount" : 1}))
res = app.execute("account", "testing", cmd2, debug = true)

acc = accounts.new "testing"
acc = app.rebuild_aggregate(accounts, "banking|account|testing", acc)
puts acc.to_json
