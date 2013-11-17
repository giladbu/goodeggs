require 'date'
require './lib/goodeggs'

SCHEDULER.every '6h', :first_in => 0 do
  good_eggs = GoodEggs.new
  good_eggs.foodshed = 'sfbay'
  product_counts = Parallel.map(GoodEggs.coming_weekdays, :in_threads => 5) do |day|
    GoodEggs::CATEGORIES.map do |category|
      products = good_eggs.products(day, category)
      [[category, day], products.length]
    end
  end.flatten(1)
  product_counts.each do |(category, day), count|
    send_event("#{category}-#{day.wday}-count",
               current: count, last: good_eggs.avg_products_count(category))
  end
end
