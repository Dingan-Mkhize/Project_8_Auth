# spec/factories/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    context 'when validating presence' do
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
    end

    context 'when validating uniqueness' do
      let!(:existing_user) { create(:user) }
      
      it 'validates uniqueness of email' do
        user = build(:user, email: existing_user.email)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("has already been taken")
      end

      it 'validates uniqueness of jti' do
        user = build(:user, jti: existing_user.jti)
        expect(user).not_to be_valid
        expect(user.errors[:jti]).to include("has already been taken")
      end
    end

    context 'when validating format' do
      it 'rejects invalid email formats' do
        invalid_emails = ['abc-123', 'wrong@', 'test@abc', 'noatsign.com']
        invalid_emails.each do |invalid_email|
          user = build(:user, email: invalid_email)
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include("is invalid")
        end
      end
    end

    context 'when testing boundary conditions' do
      it 'accepts maximum length names' do
        long_name = 'a' * 255  # Assuming the maximum length is 255
        user = build(:user, first_name: long_name, last_name: long_name)
        expect(user).to be_valid
      end

      it 'rejects overlong names' do
        overlong_name = 'a' * 256  # Assuming the maximum length is 255
        user = build(:user, first_name: overlong_name)
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("is too long (maximum is 255 characters)")
      end
    end
  end

  describe 'associations' do
    it { should have_many(:requests) }
    it { should have_many(:sent_messages).class_name('Message').with_foreign_key('sender_id') }
    it { should have_many(:received_messages).class_name('Message').with_foreign_key('receiver_id') }
    it { should have_many(:volunteerings) }
  end

  # Example method tests
  describe 'methods' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

    it '#full_name returns the concatenated first name and last name' do
      allow(user).to receive(:full_name).and_return('John Doe')
      expect(user.full_name).to eq 'John Doe'
    end
  end
end

