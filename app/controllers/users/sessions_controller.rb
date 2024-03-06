# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include RackSessionFix
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env['warden-jwt_auth.token']  # Retrieve the JWT token

    render json: {
      status: {
        code: 200, 
        message: 'Logged in successfully'
      }, 
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
      token: token  # Ensure this line has a comma at the end if there are more elements in the hash
    }
  end

  def respond_to_on_destroy
    if current_user
      render json: {
        status: 200,
        message: "Logged out"
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end

  # def refresh_token
  #   return head(:unauthorized) unless current_user

  #   new_token = Warden::JWTAuth::UserEncoder.new.call(current_user, :user, nil)
  #   render json: { token: new_token[0], exp: Time.at(new_token[1]['exp']) }, status: :ok
  # end
end
