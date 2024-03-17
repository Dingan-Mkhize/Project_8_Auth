class RequestsController < ApplicationController
  before_action :authenticate_user!, only: [:index, :create, :show, :mark_as_completed, :republish, :update]
  before_action :set_request, only: [:show, :mark_as_completed, :republish, :update]

  def index
    requests = current_user.requests.where(archived: false)
    render json: requests.as_json(only: [:id, :title])
  end

  def create
    user = User.find(params[:user_id])
    new_request_params = request_params.merge({
      archived: false,
      status: 'active',
      last_published_at: Time.current,
      volunteer_count: 0,
      fulfilled: false
    })
    request = user.requests.new(new_request_params)

    if request.save
      render json: request, status: :created
    else
      render json: request.errors, status: :unprocessable_entity
    end
  end

  def show
    # The @request instance variable is now set by the set_request method
    is_requester = @request.user == current_user
    volunteers_info = @request.volunteers.select(:id, "first_name || ' ' || last_name AS name").as_json
    messages_info = @request.messages.order(created_at: :asc).as_json(include: { sender: { only: [:id, :name, :email] } })

    render json: {
      id: @request.id,
      title: @request.title,
      description: @request.description,
      location: @request.location,
      latitude: @request.latitude,
      longitude: @request.longitude,
      date: @request.date&.strftime('%Y-%m-%d'),
      time: @request.time&.strftime('%H:%M'),
      taskType: @request.taskType,
      last_published_at: @request.last_published_at,
      volunteer_count: @request.volunteer_count,
      fulfilled: @request.fulfilled,
      isRequester: is_requester,
      volunteers: volunteers_info,
      messages: messages_info
    }
  end

  def my_requests
    requests = current_user.requests.where(archived: false)
    render json: requests.map { |request|
      {
        id: request.id,
        title: request.title,
        description: request.description,
        location: request.location,
        date: request.date&.strftime('%Y-%m-%d'),
        time: request.time&.strftime('%H:%M'),
        taskType: request.taskType
      }
    }
  end

  def mark_as_completed
    # The @request instance variable is now set by the set_request method
    if @request.update(status: 'completed', archived: true)
      render json: { message: 'Request marked as completed and archived successfully.' }, status: :ok
    else
      render json: @request.errors, status: :unprocessable_entity
    end
  end

  def republish
    # The @request instance variable is now set by the set_request method
    if can_be_republished?(@request)
      @request.update(last_published_at: Time.current, volunteer_count: 0, fulfilled: false)
      render json: { message: "Request republished successfully." }, status: :ok
    else
      render json: { error: "Request cannot be republished." }, status: :forbidden
    end
  end

  def all_active_requests
    active_requests = Request.where(status: 'active', archived: false)
    render json: active_requests
  end

  def update
    # The @request instance variable is now set by the set_request method
    if @request.update(request_params)
      render json: @request, status: :ok
    else
      render json: @request.errors, status: :unprocessable_entity
    end
  end

  private

  def set_request
    @request = current_user.requests.find_by(id: params[:id])
  end

  def request_params
    params.require(:request).permit(:title, :description, :location, :date, :time, :taskType, :latitude, :longitude)
  end

  def can_be_republished?(request)
    !request.fulfilled && request.volunteer_count < 5 && (Time.current - request.last_published_at) > 24.hours
  end
end


