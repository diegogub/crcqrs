require "./spec_helper"

Crcqrs.define_event TestEvent, {msg: {type: String, default: "-"}}
Crcqrs.define_event ManoEvent, {balance: {type: String, default: "12"}}
Crcqrs.define_event_factory TestEvent, ManoEvent
