# spec/factories/messages.rb
FactoryBot.define do
  factory :message do
    content { "Sample message content" }
    association :sender, factory: :user
    association :receiver, factory: :user
    association :request
    timestamp { Time.zone.now }
  end
end