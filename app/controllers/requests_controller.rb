class RequestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :show, :mark_as_completed, :republish]

  def create
    user = User.find(params[:user_id])
    # Set default values for status and archived explicitly
    new_request_params = request_params.merge({
      archived: false,
      status: request_params.fetch(:status, 'active'),
      last_published_at: Time.current,
      volunteer_count: 0,
      fulfilled: false # Assuming 'fulfilled' is a boolean field in your model to track fulfillment status
    })
    request = user.requests.new(new_request_params)


    if request.save
      render json: request, status: :created
    else
      render json: request.errors, status: :unprocessable_entity
    end
  end

  # Implementing the show action
  def show
    request = Request.find_by(id: params[:id])

    if request.nil?
      render json: { error: "Request not found" }, status: :not_found
      return
    end

    is_requester = request.user == current_user
    volunteers_info = request.volunteers.select(:id, :name, :profilePic).as_json

    render json: {
      id: request.id,
      title: request.title,
      description: request.description,
      location: request.location,
      date: request.date&.strftime('%Y-%m-%d'),
      time: request.time&.strftime('%H:%M'),
      taskType: request.taskType,
      last_published_at: request.last_published_at,
      volunteer_count: request.volunteer_count,
      fulfilled: request.fulfilled,
      isRequester: is_requester,
      volunteers: volunteers_info
    }
  end

  def my_requests
    requests = current_user.requests.where(archived: false).map do |request|
    {
        id: request.id,
        title: request.title,
        description: request.description,
        location: request.location,
        date: request.date&.strftime('%Y-%m-%d'), # Ensure date is formatted or nil
        time: request.time&.strftime('%H:%M'), # Ensure time is formatted or nil
        taskType: request.taskType
      }
    end
    puts "Sending myRequests: #{requests}" # Debug log
    render json: requests
  end

  # New action for marking a request as completed
  def mark_as_completed
    request = current_user.requests.find_by(id: params[:id])
    if request.nil?
      render json: { error: "Request not found" }, status: :not_found
    elsif request.update(status: 'completed', archived: true)
      render json: { message: 'Request marked as completed and archived successfully.' }, status: :ok
    else
      render json: request.errors, status: :unprocessable_entity
    end
  end

  def republish
    request = current_user.requests.find_by(id: params[:id])

    if request.nil?
      render json: { error: "Request not found" }, status: :not_found
    elsif can_be_republished?(request)
      request.update(last_published_at: Time.current, volunteer_count: 0, fulfilled: false)
      render json: { message: "Request republished successfully." }, status: :ok
    else
      render json: { error: "Request cannot be republished." }, status: :forbidden
    end
  end

  def all_active_requests
    active_requests = Request.where(status: 'active', archived: false)
                            .select(:id, :title, :description,:location, :latitude, :longitude, :date,:time, :taskType, :last_published_at,:volunteer_count)
                            .order(last_published_at: :desc)

    render json: active_requests
  end

  private

  def request_params
  params.require(:request).permit(:title, :description, :location, :date, :time, :taskType, :latitude, :longitude)
end

  def can_be_republished?(request)
    !request.fulfilled && 
      request.volunteer_count < 5 && 
      (Time.current - request.last_published_at) > 24.hours
  end
end

