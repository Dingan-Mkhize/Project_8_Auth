class Request < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :volunteerings, as: :volunteereable, dependent: :destroy
  has_many :volunteers, through: :volunteerings, source: :user

  # Constants for status values to ensure consistency
  STATUSES = { active: 'active', completed: 'completed', unfulfilled: 'unfulfilled', pending: 'pending', fulfilled: 'fulfilled' }.freeze

  # Enums for handling status values
  enum status: STATUSES

  # Validations
  validates :taskType, presence: true, inclusion: { in: ['material-need', 'one-time', 'recurring'], message: "%{value} is not a valid task type" }
  validates :status, presence: true, inclusion: { in: STATUSES.values }

  # Callbacks
  before_create :set_last_published_at

  # Determines if the request can be republished based on several conditions
  def can_be_republished?
  # puts "Debug: Last Published At: #{last_published_at}, Current Time: #{Time.current}, Comparison: #{last_published_at < 24.hours.ago}"
  !fulfilled? && volunteers.count < 5 && (last_published_at.nil? || last_published_at < 24.hours.ago)
end

  def fulfill
  update(fulfilled: true, status: :fulfilled)
end

  private

  def set_last_published_at
    self.last_published_at = Time.current
  end
end


