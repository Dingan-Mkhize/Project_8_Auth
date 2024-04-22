# spec/factories/models/volunteering_spec.rb
require 'rails_helper'

RSpec.describe Volunteering, type: :model do
  describe 'validations' do
    it 'validates presence of user_id' do
      volunteering = build(:volunteering, user: nil)
      expect(volunteering).not_to be_valid
      expect(volunteering.errors[:user_id]).to include("can't be blank")
    end

    it 'validates uniqueness scoped to user_id and volunteereable' do
      user = create(:user)
      request = create(:request)
      create(:volunteering, user: user, volunteereable: request)
      volunteering = build(:volunteering, user: user, volunteereable: request)
      expect(volunteering).not_to be_valid
      expect(volunteering.errors[:user_id]).to include("You have already volunteered for this activity.")
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:volunteereable) }
  end
end
