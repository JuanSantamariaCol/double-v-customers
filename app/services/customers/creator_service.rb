module Customers
  class CreatorService
    def initialize(params)
      @params = params
    end

    def call
      customer = Customer.new
      customer.assign_attributes(@params)

      if customer.save
        ServiceResult.success(customer)
      else
        ServiceResult.failure(customer.errors)
      end
    rescue ArgumentError => e
      # Handle invalid enum values
      customer = Customer.new(@params.except(:person_type))
      customer.errors.add(:person_type, e.message)
      ServiceResult.failure(customer.errors)
    end
  end
end
