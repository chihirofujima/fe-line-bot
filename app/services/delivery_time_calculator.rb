class DeliveryTimeCalculator
  def self.call(setting)
    new(setting).next_delivery_time
  end

  def initialize(setting)
    @setting = setting
  end

  def next_delivery_time
    now = Time.current
    today = now.to_date

    candidates = [ @setting.delivery_time_1, @setting.delivery_time_2 ].compact.map do |t|
      Time.zone.local(today.year, today.month, today.day, t.hour, t.min)
    end

    future_today = candidates.select { |t| t > now }.min
    return future_today if future_today

    next_date = next_delivery_date(today + 1)
    return nil unless next_date

    Time.zone.local(
      next_date.year,
      next_date.month,
      next_date.day,
      @setting.delivery_time_1.hour,
      @setting.delivery_time_1.min
    )
  end

  private

  def next_delivery_date(from_date)
    7.times.each do |i|
      date = from_date + i
      return date if delivery_day?(date)
    end
    nil
  end

  def delivery_day?(date)
    case @setting.frequency
    when "daily"   then true
    when "weekday" then date.wday.between?(1, 5)
    when "weekend" then [ 0, 6 ].include?(date.wday)
    end
  end
end