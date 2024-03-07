class Request < ApplicationRecord
  belongs_to :user
  has_many :messages
  # Adding volunteerings association
  has_many :volunteerings, as: :volunteereable
  has_many :volunteers, through: :volunteerings, source: :user
end

