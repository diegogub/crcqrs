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
