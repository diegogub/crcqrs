require "./spec_helper"
require "json"

define_aggregate Account, acc, {sum: {type: Int32, default: 0}, ts: {type: Time, default: Time.utc_now}}

is_valid? Account do
end

impl_event Account, AccCreated do
  if self.version == -1
    @sum = event.sum
    @ts = event.ts
  end
end

impl_event Account, MoneyDeposited do
  @sum = @sum + event.sum
end

define_commands CmdH, Account,
  {cmd: CreateAcc, event: AccCreated, create: true, prop: {sum: Int64, ts: {type: Time, default: Time.utc_now}}},
  {cmd: DeleteAcc, event: AccDeleted, prop: {ts: Time}}

acc = Account.from_json(%({}))
created = AccCreated.from_json(%({ "sum" : 100, "ts" : "2019-02-17T13:11:50+00:00" }))
acc.apply("", Int64.new(0), created)
puts ">>>#{acc.to_json}"

handler = CmdH.new
puts handler.commands

cmd = CmdH.cmd_factory("CreateAcc", "test", "")
puts ">>>#{cmd.name}"

event = Account.event("AccCreated", %({ "sum" : 3 }))
if event.create
  puts "creating"
else
  puts "not creating"
end
puts event.to_json

handler.handle(cmd)
