# spec/factories/volunteerings.rb
FactoryBot.define do
  factory :volunteering do
    association :user
    volunteereable_type { "Request" }
    association :volunteereable, factory: :request
  end
end