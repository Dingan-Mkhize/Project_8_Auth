# spec/models/message_spec.rb
require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'validations' do
    it 'validates presence of content' do
      message = build(:message, content: nil)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end

    it 'validates presence of sender_id' do
      message = build(:message, sender: nil)
      expect(message).not_to be_valid
      expect(message.errors[:sender_id]).to include("can't be blank")
    end

    it 'validates presence of receiver_id' do
      message = build(:message, receiver: nil)
      expect(message).not_to be_valid
      expect(message.errors[:receiver_id]).to include("can't be blank")
    end

    it 'validates presence of request_id' do
      message = build(:message, request: nil)
      expect(message).not_to be_valid
      expect(message.errors[:request_id]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it { should belong_to(:sender).class_name('User') }
    it { should belong_to(:receiver).class_name('User') }
    it { should belong_to(:request) }
  end
end
