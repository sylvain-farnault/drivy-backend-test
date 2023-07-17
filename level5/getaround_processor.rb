class GetaroundProcessor
  def initialize(input_datas)
    @input_datas = input_datas
  end

  def perform
    cars = @input_datas["cars"].map { |car_attributes| Car.new(car_attributes)}
    rentals = []
    options = []
    @input_datas["rentals"].each do |rental_attributes|
      begin
        rental = Rental.new(rental_attributes)
        rental.computed_nb_days = rental.compute_nb_days
        rental.car = cars.find{|car| car.id == rental.car_id }
        raise InputDataWarning, "[Warning] Car with id '#{rental.car_id}' not found. Rental with id '#{rental.id}' will be excluded from treatment" unless rental.car
        rental.computed_total_price = rental.compute_total_price
        rentals << rental
      rescue InputDataWarning => e
        puts e
      end
    end

    @input_datas["options"].each do |option_attributes|
      option = Option.new(option_attributes)
      rental = rentals.find{|rental| rental.id == option.rental_id }
      if rental
        rental.options << option
        options << option
      end
    end

    output_rentals = []
    rentals.each do |rental|
      begin
        output_rentals << {
          id: rental.id,
          options: rental.compute_options,
          actions: rental.compute_actions,
        }
      rescue InputDataWarning => e
        puts "[Warning] #{e.message}"
      end
    end
    output_rentals
  end
end
