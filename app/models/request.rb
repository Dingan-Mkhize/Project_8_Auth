class Request < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :volunteerings, as: :volunteereable
  has_many :volunteers, through: :volunteerings, source: :user

  # Add a callback to set the last_published_at when a request is created
  before_create :set_last_published_at

  validates :taskType, presence: true, inclusion: { in: ['material-need', 'one-time', 'recurring'], message: "%{value} is not a valid task type" }

  # Method to determine if the request can be republished
  def can_be_republished?
  puts "Debug inside method - Last Published At: #{last_published_at}, Current Time: #{Time.zone.now}, Comparison: #{last_published_at < 24.hours.ago}"
  !fulfilled && volunteers.count < 5 && (last_published_at.nil? || last_published_at < 24.hours.ago)
end

  # Method to update request as fulfilled
  def fulfill
    update(fulfilled: true)
  end

  private

  def set_last_published_at
    self.last_published_at = Time.current
  end
end

