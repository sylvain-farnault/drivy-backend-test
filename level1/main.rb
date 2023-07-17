require 'json'
require 'date'
file = File.read('./data/input.json')
data_hash = JSON.parse(file)

p data_hash
output = {
  rentals: []
}

data_hash["rentals"].each do |rental|
  puts rental["start_date"]
  start_date = Date.parse(rental["start_date"])
  puts rental["end_date"]
  end_date = Date.parse(rental["end_date"])
  nb_days = (end_date - start_date).to_i + 1
  puts "Nb days: #{nb_days}"

  car_id = rental["car_id"]
  car = data_hash["cars"].find{|car| car["id"] == car_id}
  price = nb_days * car["price_per_day"] + rental["distance"] * car['price_per_km']
  puts "price: #{price}"
  output[:rentals] << { id: rental["id"], price: price }
end

puts output
File.open("./data/output.json", "w") {|file| file.write(JSON.pretty_generate(output)) }
