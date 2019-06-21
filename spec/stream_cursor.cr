require "./spec_helper"

cursor = Crcqrs::StreamCursor.new
spawn do
  (0..1_000_000).each do |i|
    event = Crcqrs::RawEvent.new
    cursor.channel.send event
  end
  begin
    cursor.channel.close
  rescue
  end
end

cursor.each do |e|
  puts e
end
