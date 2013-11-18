require './lib/goodeggs'

class GoodEggsDashboard
  attr_accessor :good_eggs, :foodshed
  def initialize(foodshed, event_sender)
    @good_eggs = GoodEggs.new(foodshed)
    @foodshed = foodshed
    @event_sender = event_sender
    @product_series = {}
    @organic_breakdown = {
      :products => {organic: 0, non_organic: 0},
      :vendors => {organic: 0, non_organic: 0}
    }
  end

  def update(day, category)
    product_count = good_eggs.products(day, category).length
    organic_product_count = good_eggs.organic_products(day, category).length
    update_day_counts(category, day, product_count)
    update_organic(:products, product_count, organic_product_count)

    vendors_count = good_eggs.vendors(day, category).length
    organic_vendors_count = good_eggs.organic_vendors(day, category).length
    update_organic(:vendors, vendors_count, organic_vendors_count)
  end

  def update_day_counts(category, day, count)
    @product_series[category] ||= []
    @product_series[category] << {x: day.to_i, y: count}
    send_event("#{category}-#{day.wday}-count",
               current: count,
               last: good_eggs.avg_products_count(category))
  end

  def update_historgram()
    send_event('product_counts', series: histogram_output)
    send_event('product_categories', value: pie_output)
  end

  def update_organic(type, total_count, organic_count)
    @organic_breakdown[type][:organic] += organic_count
    @organic_breakdown[type][:non_organic] += total_count - organic_count
    data = @organic_breakdown[type].map {|k,v| {label: k, value: v}}
    send_event("organic_#{type}", value: data)
  end

  def send_event(key, data)
    key += "_#{foodshed}" unless key =~ /-count/
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
  SCHEDULER.every '30s', :first_in => 10, allow_overlapping: false do
    say "#{shed} Scheduler started"
    dashboard = GoodEggsDashboard.new(shed, self.method(:send_event))
    weekdays = GoodEggs.coming_weekdays
    GoodEggs::CATEGORIES.reduce([]) do |series, category|
      weekdays.each do |day|
        dashboard.update(day, category)
      end
      dashboard.update_historgram
    end
  end
end
