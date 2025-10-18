class CustomerSerializer
  include JSONAPI::Serializer

  attributes :name, :person_type, :identification, :email, :phone, :address, :created_at, :updated_at

  attribute :active do |customer|
    customer.active == 1
  end
end
