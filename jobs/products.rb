require './lib/goodeggs'

class GoodEggsDashboard
  attr_accessor :client
  def initialize(foodshed, event_sender)
    @client = GoodEggs.new
    @client.foodshed = foodshed
    @foodshed = foodshed
    @event_sender = event_sender
    @product_series = {}
    @organic_breakdown = {organic: 0, non_organic: 0}
  end

  def update_day_counts(category, day, count)
    @product_series[category] ||= []
    @product_series[category] << {x: day.to_i, y: count}
    send_event("#{category}-#{day.wday}-count",
               current: count,
               last: @client.avg_products_count(category))
  end

  def update_historgram()
    send_event('product_counts', series: histogram_output)
    send_event('product_categories', value: pie_output)
  end

  def update_organic_breakdown(total_count, organic_count)
    @organic_breakdown[:organic] += organic_count
    @organic_breakdown[:non_organic] += total_count - organic_count
    data = @organic_breakdown.map {|k,v| {label: k, value: v}}
    send_event('organic_products', value: data)
  end

  def send_event(key, data)
    key += "_#{@foodshed}" unless key =~ /-count/
    @event_sender.call(key, data)
  end

  def histogram_output
    @product_series.map do |category, points|
      {name: category, data: points.sort_by { |point| point[:x] } }
    end
  end

  def pie_output
    @product_series.map do |category, points|
      {
        label: category,
        value: points.reduce(0) { |mem, count| mem + count[:y] }
      }
    end
  end
end

def say(message)
  $stderr << "\e[33m#{message}\e[0m\n"
end

GoodEggs::SHEDS.each do |shed|
  SCHEDULER.every '5m', :first_in => 0 do
    say "#{shed} Scheduler started"
    dashboard = GoodEggsDashboard.new(shed, self.method(:send_event))
    good_eggs = dashboard.client
    weekdays = GoodEggs.coming_weekdays
    GoodEggs::CATEGORIES.reduce([]) do |series, category|
      Parallel.map(weekdays, :in_threads => 5) do |day|
        product_count = good_eggs.products(day, category).length
        organic_count = good_eggs.organic_products(day, category).length

        dashboard.update_day_counts(category, day, product_count)
        dashboard.update_organic_breakdown(product_count, organic_count)
      end
      dashboard.update_historgram
    end
  end
end
