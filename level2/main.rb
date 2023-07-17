require 'json'
require 'date'

class AwesomeModelBase
  def initialize(attributes)
    attributes.each do |name, value|
      instance_variable_set("@#{name}", value)
      self.class.send(:attr_accessor, name)
    end
  end
end

class Car < AwesomeModelBase
end

class Rental < AwesomeModelBase
  PRICE_PER_DAY_RULES = {
    1 => 0.9,
    4 => 0.7,
    10 => 0.5
  }

  def compute_total_price
    puts self.start_date
    start_date = Date.parse(self.start_date)
    puts self.end_date
    end_date = Date.parse(self.end_date)
    nb_days = (end_date - start_date).to_i + 1
    puts "Nb days: #{nb_days}"
    car_attributes = DATA_HASH["cars"].find{ |car| car["id"] == self.car_id }
    car = Car.new(car_attributes)

    price = 0
    ratio = 1
    (1..nb_days).each do |i|
      print "Ratio day#{i}: #{ratio} | "
      price = price + (car.price_per_day * ratio)
      ratio = PRICE_PER_DAY_RULES[i] if PRICE_PER_DAY_RULES[i]
    end
    puts ""

    price = price + (self.distance * car.price_per_km)
    price.to_i
  end
end

# get all datas
file = File.read('./data/input.json')
DATA_HASH = JSON.parse(file)

output = {
  rentals: []
}

DATA_HASH["rentals"].each do |rental_attributes|
  rental = Rental.new(rental_attributes)
  output[:rentals] << { id: rental.id, price: rental.compute_total_price }
end

puts output
File.open("./data/output.json", "w") {|file| file.write(JSON.pretty_generate(output)) }
