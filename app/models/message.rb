class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :receiver, class_name: 'User', foreign_key: 'receiver_id'
  belongs_to :request

  validates :content, presence: true
  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  validates :request_id, presence: true
end

