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
    # nb_day => ratio
    # new price_per_day after (nb_day full days ) will be (car.price_per_day * ratio)
    1 => 0.9,
    4 => 0.7,
    10 => 0.5
  }

  COMMISSION_RATIO = 0.3
  INSURANCE_FEE_RATIO = 0.5
  INSURANCE_FEE_CALCULATION = [:compute_total_price, COMMISSION_RATIO ,INSURANCE_FEE_RATIO]
  ASSISTANCE_FEE_PRICE_PER_DAY = 100
  ASSISTANCE_FEE_CACULATION = [:compute_nb_days, ASSISTANCE_FEE_PRICE_PER_DAY]


  def compute_total_price
    nb_days = compute_nb_days
    car_attributes = DATA_HASH["cars"].find{ |car| car["id"] == self.car_id }
    car = Car.new(car_attributes)

    price = 0
    ratio = 1
    (1..nb_days).each do |i|
      price = price + (car.price_per_day * ratio)
      ratio = PRICE_PER_DAY_RULES[i] if PRICE_PER_DAY_RULES[i]
    end

    price = price + (self.distance * car.price_per_km)
    price.to_i
  end

  def compute_commissions
    commissions = {
      insurance_fee: INSURANCE_FEE_CALCULATION.map{|item| item.is_a?(Symbol) ? send(item) : item }.inject(&:*).to_i,
      assistance_fee: ASSISTANCE_FEE_CACULATION.map{|item| item.is_a?(Symbol) ? send(item) : item }.inject(&:*).to_i,
    }

    commissions.merge(
      drivy_fee: (compute_total_price * COMMISSION_RATIO).to_i - (commissions[:insurance_fee] + commissions[:assistance_fee])
    )
  end

  private

  def compute_nb_days
    start_date = Date.parse(self.start_date)
    end_date = Date.parse(self.end_date)
    (end_date - start_date).to_i + 1
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

  output[:rentals] << {
    id: rental.id,
    price: rental.compute_total_price,
    commission: rental.compute_commissions
   }
end

puts output
File.open("./data/output.json", "w") {|file| file.write(JSON.pretty_generate(output)) }
