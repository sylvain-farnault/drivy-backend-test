class Rental < AwesomeModelBase
  attr_accessor :computed_nb_days, :computed_total_price, :car, :options, :actions
  def initialize(attributes)
    super(attributes)
    @computed_nb_days = nil
    @computed_total_price = nil
    @car = nil
    @options = []
    @actions = []
  end

  def compute_nb_days
    start_date = Date.parse(self.start_date)
    end_date = Date.parse(self.end_date)
    raise InputDataWarning, "Invalid rental period for Rental id '#{self.id}'. This rental will be excluded from treatment" if start_date > end_date
    (end_date - start_date).to_i + 1
  end
end
