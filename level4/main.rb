require 'json'
require 'date'

class AwesomeModelBase
  def initialize(attributes)
    attributes.each do |name, value|
      instance_variable_set("@#{name}", value)
      self.class.send(:attr_reader, name)
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

  ACTIONS = [
    %W(driver debit),
    %W(owner credit),
    %W(insurance credit),
    %W(assistance credit),
    %W(drivy credit),
  ]


  def compute_total_price
    nb_days = compute_nb_days
    car_attributes = DATA_HASH["cars"].find{ |car| car["id"] == self.car_id }
    raise StandardError, "Car with id '#{self.car_id}' not found" unless car_attributes
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

  def compute_actions
    actions = []
    ACTIONS.each do |action|
      actions << {
        who: action.first,
        type: action.last,
        amount: send("compute_#{action.join('_')}", actions)
      }
    end
    actions
  end

  private

  def compute_nb_days
    start_date = Date.parse(self.start_date)
    end_date = Date.parse(self.end_date)
    raise StandardError, "Invalid rental period for Rental id '#{self.id}'" if start_date > end_date
    (end_date - start_date).to_i + 1
  end

  def compute_driver_debit(actions)
    self.compute_total_price
  end

  def compute_owner_credit(actions)
    # (self.compute_total_price * (1 - COMMISSION_RATIO)).to_i
    total_price = actions.find{|a| a[:who] == 'driver' && a[:type] == 'debit' }[:amount]
    (total_price * (1 - COMMISSION_RATIO)).to_i
  end

  def compute_insurance_credit(actions)
    INSURANCE_FEE_CALCULATION.map{|item| item.is_a?(Symbol) ? send(item) : item }.inject(&:*).to_i
  end

  def compute_assistance_credit(actions)
    ASSISTANCE_FEE_CACULATION.map{|item| item.is_a?(Symbol) ? send(item) : item }.inject(&:*).to_i
  end

  def compute_drivy_credit(actions)
    debits = actions.select{ |d| d[:type] == "debit" }.sum{|d| d[:amount]}
    credits = actions.select{ |d| d[:type] == "credit" }.sum{|d| d[:amount]}
    debits - credits
  end

end

# get all datas
file = File.read('./data/input.json')
DATA_HASH = JSON.parse(file)


begin
  output_rentals = []
  DATA_HASH["rentals"].each do |rental_attributes|
    rental = Rental.new(rental_attributes)

    output_rentals << {
      id: rental.id,
      actions: rental.compute_actions
    }
  end

  puts output_rentals
  File.open("./data/output.json", "w") do |file|
    file.write(JSON.pretty_generate(
      {
        rentals: output_rentals
      }
    ))
  end
rescue StandardError => e
  puts "Error: #{e.message}"
end
