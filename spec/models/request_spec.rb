# spec/models/request_spec.rb
require 'rails_helper'

RSpec.describe Request, type: :model do
  # Validation tests
  describe 'validations' do
    it 'validates presence of taskType' do
      expect(build(:request, taskType: nil)).not_to be_valid
    end

    it 'validates inclusion of taskType in expected values' do
      valid_types = ['material-need', 'one-time', 'recurring']
      valid_types.each do |type|
        expect(build(:request, taskType: type)).to be_valid
      end

      expect(build(:request, taskType: 'invalid-type')).not_to be_valid
    end

    it 'is not valid without a user' do
      request = build(:request, user: nil)
      expect(request).not_to be_valid
      expect(request.errors[:user]).to include("must exist")
    end
  end

  # Association tests
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:messages) }
    it { should have_many(:volunteerings) }
    it { should have_many(:volunteers).through(:volunteerings) }
  end

  # Methods tests
  describe 'methods' do
    let(:user) { create(:user) }
    let(:request) do
    create(:request, user: user, last_published_at: Time.current - 26.hours, fulfilled: false, volunteer_count: 0)
  end

  describe '#can_be_republished?' do
  context 'when conditions for republishing are met' do
    it 'returns true if the request is not fulfilled, has less than 5 volunteers, and was last published more than 24 hours ago' do
      user = create(:user)
      request = create(:request, user: user, fulfilled: false, volunteer_count: 0)
      # Explicitly set last_published_at here
      request.update(last_published_at: Time.zone.now - 26.hours)
      puts "Fulfilled condition: #{!request.fulfilled}"
      puts "Volunteers condition: #{request.volunteers.count < 5}"
      puts "Last Published At condition: #{request.last_published_at < 24.hours.ago}"
      puts "Current Time: #{Time.zone.now}"
      expect(request.can_be_republished?).to eq(true)
    end
  end

      context 'when the request is fulfilled' do
        before { request.update(fulfilled: true) }
        it 'returns false' do
          expect(request.can_be_republished?).to eq(false)
        end
      end

      context 'when the request has 5 or more volunteers' do
        before { 5.times { request.volunteers << create(:user) } }
        it 'returns false' do
          puts "Volunteers count after adding 5: #{request.volunteers.count}"
          expect(request.can_be_republished?).to eq(false)
        end
      end

      context 'when the request was last published less than 24 hours ago' do
        before { request.update(last_published_at: 1.hour.ago) }
        it 'returns false' do
          expect(request.can_be_republished?).to eq(false)
        end
      end
    end
  end

  # Callback tests
  describe 'callbacks' do
    it 'sets last_published_at before creation' do
      new_request = create(:request)
      expect(new_request.last_published_at).to be_present
    end
  end
end

