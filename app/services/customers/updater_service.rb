module Customers
  class UpdaterService
    def initialize(customer, params)
      @customer = customer
      @params = params
    end

    def call
      @customer.assign_attributes(@params)

      if @customer.save
        ServiceResult.success(@customer)
      else
        ServiceResult.failure(@customer.errors)
      end
    rescue ArgumentError => e
      # Handle invalid enum values
      @customer.errors.add(:person_type, e.message)
      ServiceResult.failure(@customer.errors)
    end
  end
end
