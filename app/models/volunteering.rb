class Volunteering < ApplicationRecord
  belongs_to :user
  belongs_to :volunteereable, polymorphic: true
end
