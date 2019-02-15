require "./spec_helper"
require "json"

class CreateAcc < Crcqrs::Cmd
  def name
    "CreateAcc"
  end

  def default_event_type
    "AccCreated"
  end
end

class Test < Crcqrs::Aggregate

  JSON.mapping(
    count: { type: Int64, default: Int64.new(0) ,nilable: true},
  )

  def initialize(@id)
    super
    @count = Int64.new(0)
  end

  def prefix : String
    "t"
  end
end

describe Crcqrs do
  puts CreateAcc.new("{}").to_json

  puts Test.new("").to_json
end
