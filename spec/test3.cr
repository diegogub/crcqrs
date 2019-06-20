require "./spec_helper"
Crcqrs.aggregate_root(Accounts, "account","acc", Account,{ balance: { type: Int64, default: 0_i64},owner: { type: String, default: "-"}},AccountCreated,AccountDeposited)
Crcqrs.define_event AccountCreated, { balance: { type: Int64, default: 0_i64}}
Crcqrs.define_event AccountDeposited, { amount: { type: Int64, default: 0_i64}}
accounts = Accounts.new
app = Crcqrs::App.new("banking","bk")Â
app.add_aggregate(accounts)
