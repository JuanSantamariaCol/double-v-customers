FactoryBot.define do
  factory :outbox_message do
    aggregate_id { "1" }
    aggregate_type { "Customer" }
    event_type { "customer.created" }
    payload { { id: 1, name: "Test Customer", email: "test@example.com" }.to_json }
    status { :pending }

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :failed do
      status { :failed }
      error_message { "Failed to publish event" }
    end

    trait :customer_created do
      event_type { "customer.created" }
    end

    trait :customer_updated do
      event_type { "customer.updated" }
    end

    trait :customer_deleted do
      event_type { "customer.deleted" }
    end
  end
end
