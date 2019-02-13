require "./spec_helper"

class CreateAcc < Crcqrs::Cmd
  def name
    "CreateAcc"
  end

  def default_event_type
      "AccCreated"
  end
end

describe Crcqrs do
    puts CreateAcc.new("{}").to_json
end
