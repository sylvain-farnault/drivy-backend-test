module Getaround
  class AddPaiementAction
    def initialize(rental)
      @rental = rental
    end

    def proceed_with(who, type, amount)
      puts "Add action for Rent_#{@rental.id}: #{who}/#{type} => #{amount}"
      # look if action exist in actions with attributes (less amount)
      action = @rental.actions.find do |action|
        action.rental_id == @rental.id &&
        action.who == who &&
        action.type == type
      end
      if action
        # if so increment amount
        action.amount = action.amount + amount
        #-@rental.actions << action
      else
        # else Action.new(attributes) et rental.actions << new_action
         new_action = Action.new(
          "rental_id" => @rental.id,
          "who" => who,
          "type" => type,
          "amount" => amount
        )
        @rental.actions << new_action
      end
    end

  end
end
