module Customers
  class UpdaterService
    def initialize(customer, params)
      @customer = customer
      @params = params.to_h.symbolize_keys
    end

    def call
      @customer.assign_attributes(@params)

      if @customer.save
        ServiceResult.success(@customer)
      else
        ServiceResult.failure(@customer.errors)
      end
    rescue ArgumentError => e

      @customer.errors.add(:person_type, e.message) if e.message.include?("is not a valid person_type")
      ServiceResult.failure(@customer.errors)
    end
  end
end
