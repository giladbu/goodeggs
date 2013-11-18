require 'date'
require './lib/goodeggs'

def update_day_counts(category, data, good_eggs)
  data.each do |day_count|
    day = Time.at(day_count[:x])
    count = day_count[:y]
    send_event("#{category}-#{day.wday}-count",
               current: count,
               last: good_eggs.avg_products_count(category))
  end
end

SCHEDULER.every '3m', :first_in => 0 do
  good_eggs = GoodEggs.new
  good_eggs.foodshed = 'sfbay'
  GoodEggs::CATEGORIES.reduce([]) do |series, category|
    points = Parallel.map(GoodEggs.coming_weekdays, :in_threads => 5) do |day|
      count = good_eggs.products(day, category).length
      {x: day.to_i, y: count}
    end
    update_day_counts(category, points, good_eggs)
    series << {data: points, name: category}
    send_event("product_counts", series: series)
    series
  end
end
