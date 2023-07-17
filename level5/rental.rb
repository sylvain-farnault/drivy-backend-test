class Rental < AwesomeModelBase
  attr_accessor :car, :options
  def initialize(attributes)
    super(attributes)
    @car = nil
    @options = []
  end


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

    price = 0
    ratio = 1
    (1..nb_days).each do |i|
      price = price + (car.price_per_day * ratio)
      ratio = PRICE_PER_DAY_RULES[i] if PRICE_PER_DAY_RULES[i]
    end

    price = price + (self.distance * car.price_per_km)
    price.to_i
  end

  def compute_options
    self.options.map(&:type)
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
    raise InputDataWarning, "Invalid rental period for Rental id '#{self.id}'. This rental will be excluded from treatment" if start_date > end_date
    (end_date - start_date).to_i + 1
  end

  def compute_driver_debit(actions)
    self.compute_total_price + self.compute_total_options_price
  end

  def compute_owner_credit(actions)
    total_price = self.compute_total_price

    select_option_prices = Option::PRICES.select{|option_price|
      option_price[:target_action] == ["owner", "credit"] &&
      self.compute_options.include?(option_price[:type])
    }

    options_price = select_option_prices.reduce(0){|total, option_price|
      total + (option_price[:price_per_day] * self.compute_nb_days)
    }


    ((total_price * (1 - COMMISSION_RATIO)) + options_price).to_i
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

  def compute_total_options_price
    self.options.reduce(0){|total, option|
      option_pp_day = Option::PRICES.find{|option_price|
        option_price[:type] == option.type
      }[:price_per_day]
      total + (option_pp_day * self.compute_nb_days)
    }
  end

end
