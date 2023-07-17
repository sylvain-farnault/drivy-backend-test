require 'json'
require 'date'
require_relative 'getaround_models'
require_relative 'rental'
require_relative 'getaround_processor'

# get all datas
file = File.read('./data/input.json')
input_datas = JSON.parse(file)

#
gp = GetaroundProcessor.new(input_datas)
output_rentals = gp.perform

File.open("./data/output.json", "w") do |file|
  file.write(JSON.pretty_generate(
    {
      rentals: output_rentals
    }
  ))
end
