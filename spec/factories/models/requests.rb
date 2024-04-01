# spec/factories/models/requests.rb
FactoryBot.define do
  factory :request do
    association :user
    description { "A sample request description." }
    status { "active" }
    taskType { ["material-need", "one-time", "recurring"].sample }
    location { "Some location" }
    # Add any other fields that are required and have validations
  end
end