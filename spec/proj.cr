require "./spec_helper"

pg_store = Crcqrs::PostgresStore.new "banking"
pg_store.init

view = Crcqrs::MemoryProjection.new "testing", pg_store
view.run
