class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
    
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: self
    
  # Attach a government_id to the user
  has_one_attached :government_id

  # User-Request association
  has_many :requests
  
  # Associations for sent messages and received messages
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id'
  has_many :received_messages, class_name: 'Message', foreign_key: 'receiver_id'
  # Volunteering associations
  has_many :volunteerings
  has_many :volunteered_requests, through: :volunteerings, source: :volunteereable, source_type: 'Request'
end
