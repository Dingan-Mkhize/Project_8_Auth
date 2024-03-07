class RequestsController < ApplicationController
  before_action :authenticate_user!, only: [:create] # Ensure user is logged in

  def create
    # Assumes you have set up Devise for user authentication
    user = User.find(params[:user_id]) # Find the user based on the user_id in the route
    request = user.requests.new(request_params)

    if request.save
      render json: request, status: :created
    else
      render json: request.errors, status: :unprocessable_entity
    end
  end

  def my_requests
  requests = current_user.requests.map do |request|
    {
      id: request.id,
      title: request.title,
      description: request.description,
      location: request.location,
      date: request.date&.strftime('%Y-%m-%d'), # Format date as "YYYY-MM-DD"
      time: request.time&.strftime('%H:%M'), # Format time as "HH:MM", omitting seconds
      taskType: request.taskType
    }
  end
  render json: requests
end

  private

  def request_params
    params.require(:request).permit(:title, :description, :location, :date, :time, :taskType)
  end
end

