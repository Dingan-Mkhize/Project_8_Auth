# spec/models/request_spec.rb
require 'rails_helper'

RSpec.describe Request, type: :model do
  describe 'validations' do
    # existing validation tests
  end

  describe 'associations' do
    # existing association tests
  end

  describe '#can_be_republished?' do
    let(:user) { create(:user) }
    let(:request) { create(:request, user: user, volunteer_count: 4) }  # assumes factory sets last_published_at correctly

    context 'when not fulfilled and has fewer than 5 volunteers' do
      before do
        request.update(fulfilled: false, volunteer_count: 4)
      end

      it 'returns true if last published more than 24 hours ago' do
        request.update(last_published_at: 25.hours.ago)
        expect(request.can_be_republished?).to be true
      end

      it 'returns false if last published less than 24 hours ago' do
        request.update(last_published_at: 23.hours.ago)
        expect(request.can_be_republished?).to be false
      end

      it 'returns true if last published exactly 24 hours ago' do
        request.update(last_published_at: 24.hours.ago)
        expect(request.can_be_republished?).to be true
      end
    end

    context 'when fulfilled or has 5 or more volunteers' do
      it 'returns false if fulfilled' do
        request.update(fulfilled: true)
        expect(request.can_be_republished?).to be false
      end

      it 'returns false if has 5 or more volunteers' do
        request.update(volunteer_count: 5)
        expect(request.can_be_republished?).to be false
      end
    end
  end

  describe 'callbacks' do
    # existing callbacks tests
  end
end

