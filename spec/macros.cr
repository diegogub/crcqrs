require "./spec_helper"

events [AccCreated, {name: {type: String, default: ""}}, true],
  [MoneySent, {amount: {type: Int32, default: 0}}]

event_valid? AccCreated do
  if @name == ""
    false
  end
end

event_valid? MoneySent do
  if @amount == 0
    false
  end
end

puts build_event("AccCreated").create

aggregate Account, pm, {name: {type: String, default: ""}, balance: {type: Int32, default: 0}},
  AccCreated,
  MoneySent

aggregate_valid? Account do
  if @name == ""
    raise Exception.new("Invalid name for account")
  end
end

store = Crcqrs::EventoStore.new("localhost", 6060)

10.times do
  pm = Account.create
  puts pm.id
  puts pm.stream
  pm = store.replay(pm)
end
