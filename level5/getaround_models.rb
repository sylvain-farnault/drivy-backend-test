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

class Option < AwesomeModelBase
    PRICES = [
      { type: "gps", price_per_day: 500, target_action: %W(owner credit) },
      { type: "baby_seat", price_per_day: 200, target_action: %W(owner credit) },
      { type: "additional_insurance", price_per_day: 1000, target_action: %W(drivy credit)}
  ]
end
