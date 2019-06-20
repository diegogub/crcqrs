require "./spec_helper"


Crcqrs.aggregate_root(Accounts, "account","acc", Account,{ balance: { type: Int64, default: 0_i64},owner: { type: String, default: "-"}},AccountCreated,AccountDeposited)

Crcqrs.define_event AccountCreated, { balance: { type: Int64, default: 0_i64}}


Crcqrs.define_event AccountDeposited, { amount: { type: Int64, default: 0_i64}}
Crcqrs.apply_event Account,AccountDeposited do
    self.balance += event.amount
end


accounts = Accounts.new
app = Crcqrs::App.new("banking","bk")
app.add_aggregate(accounts)

acc = accounts.new "testing"
puts acc.to_json
deposit = accounts.gen_event("AccountDeposited",%({ "amount" : 12}))
acc.apply(deposit)
deposit = accounts.gen_event("AccountDeposited",%({ "amount" : 12}))
acc.apply(deposit)
deposit = accounts.gen_event("AccountDeposited",%({ "amount" : 12}))
acc.apply(deposit)
deposit = accounts.gen_event("AccountDeposited",%({ "amount" : -100}))
acc.apply(deposit)
puts acc.to_json
