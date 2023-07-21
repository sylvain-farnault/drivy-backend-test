class GetaroundProcessor
  def initialize(input_datas)
    @input_datas = input_datas
  end

  def perform
    # Convert input data to models
    cars = @input_datas["cars"].map { |car_attributes| Car.new(car_attributes)}
    rentals = []
    options = []
    actions = []
    @input_datas["rentals"].each do |rental_attributes|
      begin
        rental = Rental.new(rental_attributes)

        rental.computed_nb_days = rental.compute_nb_days
        rental.car = cars.find{|car| car.id == rental.car_id }
        raise InputDataWarning, "[Warning] Car with id '#{rental.car_id}' not found. Rental with id '#{rental.id}' will be excluded from treatment" unless rental.car
        rentals << rental
      rescue InputDataWarning => e
        puts e
      end
    end

    @input_datas["options"].each do |option_attributes|
      begin
        option = Option.new(option_attributes)
        rental = rentals.find{|rental| rental.id == option.rental_id }
        raise InputDataWarning, "[Warning] Rental with id '#{option.rental_id}' not found. Option with id '#{option.id}' will be excluded from treatment" unless rental
        rental.options << option
        options << option
      rescue InputDataWarning => e
        puts e
      end
    end
    # [END] Convert input data to models

    # compute all paiement actions
    output_rentals = []
    rentals.each do |rental|
      begin
        price_calculator = Getaround::PriceCalculator.new(rental)
        add_paiement_action =  Getaround::AddPaiementAction.new(rental)

        rental.computed_total_price = price_calculator.compute_total_price_commissionable
        add_paiement_action.proceed_with("driver", "debit", rental.computed_total_price)
        add_paiement_action.proceed_with("driver", "debit", price_calculator.compute_amount_from_options)
        add_paiement_action.proceed_with("owner", "credit", price_calculator.compute_amount_with_commission_off)
        add_paiement_action.proceed_with("owner", "credit", price_calculator.compute_amount_from_uncommissionable_options)
        add_paiement_action.proceed_with("insurance", "credit", price_calculator.compute_insurance_credit)
        add_paiement_action.proceed_with("assistance", "credit", price_calculator.compute_assistance_credit)
        add_paiement_action.proceed_with("drivy", "credit", price_calculator.compute_drivy_credit)

        output_rentals << {
          id: rental.id,
          options: rental.options.map(&:type),
          actions: rental.actions.map{|a|
            {
              who: a.who,
              type: a.type,
              amount: a.amount
            }
          }
        }
      rescue InputDataWarning => e
        puts "[Warning] #{e.message}"
      end
    end
    output_rentals
  end
end
