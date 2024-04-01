# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  it 'validates presence of email' do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it 'validates presence of password' do
    user = build(:user, password: nil, password_confirmation: nil)
    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("can't be blank")
  end

  it 'validates uniqueness of email' do
    create(:user, email: 'test@example.com')
    user = build(:user, email: 'test@example.com')
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("has already been taken")
  end

  it 'validates uniqueness of jti' do
    original_user = create(:user)
    user = build(:user, jti: original_user.jti)
    expect(user).not_to be_valid
    expect(user.errors[:jti]).to include("has already been taken")
  end

  it 'validates format of email' do
    user = build(:user, email: 'invalid_format')
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("is invalid")
  end

  describe 'associations' do
    it { should have_many(:requests) }
    it { should have_many(:sent_messages).class_name('Message').with_foreign_key('sender_id') }
    it { should have_many(:received_messages).class_name('Message').with_foreign_key('receiver_id') }
    it { should have_many(:volunteerings) }
  end

  # Example test for a hypothetical 'full_name' method
  # it '#full_name returns the concatenated first name and last name' do
  #   user = build(:user, first_name: 'John', last_name: 'Doe')
  #   expect(user.full_name).to eq 'John Doe'
  # end

  # Add tests for any other instance methods here...
end
