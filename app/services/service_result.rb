class ServiceResult
  attr_reader :customer, :errors

  def initialize(success, customer: nil, errors: nil)
    @success = success
    @customer = customer
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(customer)
    new(true, customer: customer)
  end

  def self.failure(errors)
    new(false, errors: errors)
  end
end
