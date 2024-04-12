class Volunteering < ApplicationRecord
  belongs_to :user
  belongs_to :volunteereable, polymorphic: true

  validates :user_id, presence: true
  validates :volunteereable_id, presence: true
  validates :volunteereable_type, presence: true

  # Ensure a user can't volunteer more than once for the same request
  validates :user_id, uniqueness: { scope: [:volunteereable_type, :volunteereable_id],
                                    message: "You have already volunteered for this activity." }
end

