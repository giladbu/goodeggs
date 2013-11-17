require 'httparty'
require 'active_support/time'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/string/inflections'
require 'parallel'

class GoodEggs
  SHEDS = %i{sfbay nyc nola la}
  CATEGORIES = %i{produce dairy meat bakery local kitchen baby event}

  include HTTParty
  base_uri 'goodeggs.com'

  attr_accessor :foodshed

  def get_product_listing(params = {})
    pickup_day = self.class.weekday(params.delete(:pickup_day) || 2.days.from_now)
    request_params = params.reverse_merge(
      :pickupDay => formatted_date(pickup_day)
    )
    self.class.get("/#{foodshed}/product_listings", :query => request_params)
  end

  def products(day, category)
    @data ||= {}
    @data[category] ||= {}
    @data[category][formatted_date(day)] ||= get_product_listing(:pickup_day => day,
                                                                 :category => category)
    @data[category][formatted_date(day)]['products']
  end

  def vendors(day, category)
    @data ||= {}
    @data[category] ||= {}
    @data[category][formatted_date(day)] ||= get_product_listing(:pickup_day => day,
                                                                 :category => category)
    @data[category][formatted_date(day)]['vendors']
  end

  def avg_products_count(category)
    category_data = @data.fetch(category, {})
    total_products_count = category_data.reduce(0) {|mem, (date, data)| mem + data['products'].length }
    total_products_count / category_data.length
  end

  def self.pretty_name(category)
    category.capitalize
  end

  def self.weekday(time)
    if (1..5).include?(time.wday)
      time
    else
      time.beginning_of_week + 1.week
    end
  end

  def self.coming_weekdays(start = Time.now)
  day = (start - Time.now) >= 2.days ? start : Time.now + 2.days
  weekdays = [weekday(day)]
  while weekdays.length < 5
    day = weekday(day + 1.day)
    weekdays << day
  end
  weekdays
end


protected

  def formatted_date(time)
    time.strftime('%Y-%m-%d')
  end

end
