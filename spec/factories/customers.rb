FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "#{Faker::Name.name} #{n}" }
    person_type { [:natural, :empresa].sample }
    sequence(:identification) { |n| "#{Faker::Number.number(digits: 10)}#{n}" }
    sequence(:email) { |n| "customer#{n}@#{Faker::Internet.domain_name}" }
    phone { Faker::PhoneNumber.cell_phone }
    address { Faker::Address.full_address }
    active { 1 }

    trait :natural do
      person_type { :natural }
    end

    trait :empresa do
      person_type { :empresa }
      name { Faker::Company.name }
    end

    trait :inactive do
      active { 0 }
    end
  end
end
