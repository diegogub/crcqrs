require "./spec_helper"


define_aggregate Account, acc, { sum: { type: Int32, default: 0}, ts: {type: Time, default: Time.utc_now }}

is_valid? Account do
end

define_commands CmdH, Account, { cmd: CreateAcc, event: AccCreated , create: true, prop: { sum: Int64, ts: {type: Time, default: Time.utc_now} } },
              { cmd: DeleteAcc, event: AccDeleted, prop: { ts: Time } }

impl_event Account, AccCreated do
  @sum = @sum + event.sum
  @ts = event.ts
end

acc = Account.from_json(%({}))
acc.id = "testing"

event = Account.event("AccCreated",%({ "sum" : 3 }))
store = Crcqrs::EventoStore.new("localhost",6060)

result = store.save(acc,event)
case typeof(result)
when Int64
  puts "saved event"
else
  puts "Failed to save event: #{result}"
end

store.replay(acc)
