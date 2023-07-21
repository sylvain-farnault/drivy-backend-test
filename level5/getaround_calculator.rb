# TODO: If needed we should define business rounding rules

module Getaround
  class PriceCalculator
    PRICE_PER_DAY_RULES = {
      # nb_day => ratio
      # new price_per_day after (nb_day full days ) will be (car.price_per_day * ratio)
      1 => 0.9,
      4 => 0.7,
      10 => 0.5
    }

    COMMISSION_RATIO = 0.3
    INSURANCE_FEE_RATIO = 0.5
    ASSISTANCE_FEE_PRICE_PER_DAY = 100

    # A suppr
    ACTIONS = [
      %W(driver debit),
      %W(owner credit),
      %W(insurance credit),
      %W(assistance credit),
      %W(drivy credit),
    ]

    def initialize(rental)
      @rental = rental
    end

    def compute_total_price_commissionable
      # for action driver/debit
      compute_amount_from_periode + compute_amount_from_distance
    end

    def compute_amount_from_options
      # for action driver/debit
      @rental.options.reduce(0){|total, option|
        option_pp_day = Option::PRICES.find{|option_price|
          option_price[:type] == option.type
        }[:price_per_day]
        total + (option_pp_day * @rental.computed_nb_days)
      }
    end

    def compute_amount_with_commission_off
      # for owner/credit
      total_price = @rental.computed_total_price
      (total_price * (1 - COMMISSION_RATIO)).round
    end

    def compute_amount_from_uncommissionable_options
      # for owner/credit
      # We first select options with full credit to owner AND choosen in rental
      select_option_prices = Option::PRICES.select{|option_price|
        option_price[:target_action] == ["owner", "credit"] &&
        @rental.options.map(&:type).include?(option_price[:type])
      }
      # Then compute total regarding nb_days
      amount = select_option_prices.reduce(0){|total, option_price|
        total + (option_price[:price_per_day] * @rental.computed_nb_days)
      }

      amount.round
    end

    def compute_insurance_credit
      # for insurance/credit
      (@rental.computed_total_price * COMMISSION_RATIO * INSURANCE_FEE_RATIO).round
    end

    def compute_assistance_credit
      # for assistance/credit
      @rental.computed_nb_days * ASSISTANCE_FEE_PRICE_PER_DAY
    end

    def compute_drivy_credit
      # for drivy/credit
      debits = @rental.actions.select{ |a| a.type == "debit" }.sum{|a| a.amount}
      credits = @rental.actions.select{ |a| a.type == "credit" }.sum{|a| a.amount}
      debits - credits
    end

    private

    def compute_amount_from_periode
      # for action driver/debit
      nb_days = @rental.computed_nb_days

      amount = 0
      ratio = 1
      (1..nb_days).each do |i|
        amount = amount + (@rental.car.price_per_day * ratio)
        ratio = PRICE_PER_DAY_RULES[i] if PRICE_PER_DAY_RULES[i]
      end

      amount.round
    end

    def compute_amount_from_distance
      # for action driver/debit
      amount = @rental.distance * @rental.car.price_per_km
      amount.round
    end
  end
end
