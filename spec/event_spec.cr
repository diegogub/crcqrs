require "./spec_helper"


define_aggregate Account, acc, { sum: { type: Int32, default: 0}, last_deposit: {type: Time, default: Time.utc_now }, ts: {type: Time, default: Time.utc_now }}

is_valid? Account do
end

define_commands CmdH,
              { agg: Account, cmd: CreateAcc, event: AccCreated , create: true, prop: { sum: Int32, ts: {type: Time, default: Time.utc_now} } },
              { agg: Account, cmd: DepositMoney, event: MoneyDeposited , prop: { sum: Int32, ts: {type: Time, default: Time.utc_now} } },
              { agg: Account, cmd: DeleteAcc, event: AccDeleted, prop: { ts: Time } }


cmd_handler = CmdH.new

impl_event Account, AccCreated do
  @sum = event.sum
  @ts = event.ts
end

impl_event Account, MoneyDeposited do
  @sum = @sum + event.sum
  @last_deposit = event.ts
end


# INPUT
agg_id = "test_acc"
cmd_name = "CreateAcc"
data = %({ "sum" : 100 })
store = Crcqrs::EventoStore.new("localhost",6060)

# EMIT COMMAND
cmd = CmdH.cmd_factory(cmd_name,agg_id,data)
event = cmd_handler.handle(cmd)

# INSTANCE OF AGGREGATE
acc = CmdH.emit_agg(cmd,agg_id)
puts acc.to_json

# REGENERATE AGGREATE FROM EVENT STORE
store.replay(acc)
puts acc.stream

# APPLY EVENT TO AGGREGATE
acc.apply(store,false,acc.version + 1,event)

puts acc.to_json
sleep 5

100.times do  |i|
  cmd_name = "DepositMoney"
  data = %({ "sum" : 1 })

  # EMIT COMMAND
  cmd = CmdH.cmd_factory(cmd_name,agg_id,data)
  event = cmd_handler.handle(cmd)

  # APPLY EVENT TO AGGREGATE
  acc.apply(store,false,acc.version + 1,event)
end

puts acc.to_json
