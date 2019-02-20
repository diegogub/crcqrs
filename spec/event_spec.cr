require "./spec_helper"
require "./account"

define_commands CmdH,
  # # Account commands
  {agg: Account, cmd: CreateAcc, event: AccCreated, create: true,
   prop: {sum: Int32, ts: {type: Time, default: Time.utc_now}}},
  {agg: Account, cmd: DepositMoney, event: MoneyDeposited,
   prop: {sum: Int32,
          ts: {type: Time, default: Time.utc_now}},
  }

cmd_handler = CmdH.new

# INPUT
agg_id = "test_acc"
cmd_name = "CreateAcc"
data = %({ "sum" : 0 })
store = Crcqrs::EventoStore.new("localhost", 6060)

# EMIT COMMAND
cmd = CmdH.cmd_factory(cmd_name, agg_id, data)
event = cmd_handler.handle(cmd)

# INSTANCE OF AGGREGATE
acc = CmdH.emit_agg(cmd, agg_id)
puts acc.to_json

# REGENERATE AGGREATE FROM EVENT STORE
store.replay(acc)
puts acc.stream
puts acc.to_json

# APPLY EVENT TO AGGREGATE
acc = acc.apply(store, false, acc.version + 1, event)
puts store.save(acc, event)

puts acc.to_json

10.times do |i|
  cmd_name = "DepositMoney"
  data = %({ "sum" : -50 })

  # EMIT COMMAND
  cmd = CmdH.cmd_factory(cmd_name, agg_id, data)
  event = cmd_handler.handle(cmd)

  # APPLY EVENT TO AGGREGATE
  acc = acc.apply(store, false, acc.version + 1, event)
  store.save(acc, event)
end
puts acc.to_json
