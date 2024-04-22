# spec/factories/requests.rb
FactoryBot.define do
  factory :request do
    association :user
    description { "A sample request description." }
    status { "active" }
    taskType { ["material-need", "one-time", "recurring"].sample }
    location { "Some location" }
    last_published_at { 26.hours.ago } # Default to a republishable state
    fulfilled { false }
    volunteer_count { 3 }  # Default to less than 5 volunteers

    trait :republishable do
      last_published_at { 26.hours.ago }
      fulfilled { false }
      volunteer_count { 3 }
    end

    trait :non_republishable do
      last_published_at { 23.hours.ago }
      fulfilled { false }
      volunteer_count { 5 }
    end
  end
end
