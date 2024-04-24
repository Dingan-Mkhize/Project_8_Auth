# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  respond_to :json
  before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
# POST /resource
def create
  build_resource(sign_up_params)

  resource.save
  yield resource if block_given?
  if resource.persisted?
    if resource.active_for_authentication?
      sign_up(resource_name, resource)
      token = response.headers['Authorization'].split(' ').last if response.headers['Authorization'].present?
      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
        token: token
      }, status: :created
    else
      expire_data_after_sign_in!
      render json: { status: { code: 422, message: 'User registered but not active.' } }, status: :unprocessable_entity
    end
  else
    clean_up_passwords resource
    set_minimum_password_length
    render json: { status: { code: 422, message: resource.errors.full_messages.to_sentence } }, status: :unprocessable_entity
  end
end


  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password, :password_confirmation, :government_id])
end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
  
  private

  def respond_with(resource, _opts = {})
  if resource.persisted?
    token = response.headers['Authorization'].split(' ').last if response.headers['Authorization'].present?
    render json: {
      status: {code: 200, message: 'Signed up successfully.'},
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
      token: token
    }
  else
    render json: {
      status: {code: 422, message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"}
    }, status: :unprocessable_entity
  end
end

end
