FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'testpassword' }
    password_confirmation { 'testpassword' }
    # Include other necessary attributes as needed
  end
end
