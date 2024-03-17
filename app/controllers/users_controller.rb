class UsersController < ApplicationController
  before_action :authenticate_user!

  def messageable
    messageable_users = User.where.not(id: current_user.id)
    
    user_data = messageable_users.map do |user|
      {
        id: user.id,
        name: user.full_name,
        profile_pic_url: user.profile_pic_url
      }
    end
    
    render json: user_data
  end
end
