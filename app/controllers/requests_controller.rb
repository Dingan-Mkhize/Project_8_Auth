class RequestsController < ApplicationController
  before_action :authenticate_user!, only: [:index, :create, :show, :mark_as_completed, :republish, :update, :volunteer]
  before_action :set_request, only: [:show, :mark_as_completed, :republish, :update, :volunteer]

  def index
    own_requests = current_user.requests.where(archived: false)
    volunteered_requests = Request.joins(:volunteerings).where(volunteerings: { user_id: current_user.id }, archived: false)
    combined_requests = (own_requests + volunteered_requests).uniq
    render json: combined_requests.as_json(only: [:id, :title], include: {user: { only: [:id, :first_name, :last_name]}})
  end

  def create
    new_request_params = request_params.merge({
      user_id: params[:user_id],
      archived: false,
      status: 'active',
      last_published_at: Time.current,
      volunteer_count: 0,
      fulfilled: false,
      hidden: false
    })
    request = Request.new(new_request_params)
    if request.save
      render json: request, status: :created
    else
      render json: request.errors, status: :unprocessable_entity
    end
  end

  def show
    is_requester = @request.user == current_user
    volunteers_info = @request.volunteers.select(:id, "first_name || ' ' || last_name AS name").as_json
    messages_info = @request.messages.where("sender_id = ? OR receiver_id = ?", current_user.id, current_user.id).order(created_at: :asc)
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
      messages: messages_info.as_json(include: { sender: { only: [:id, :name, :email] } })
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
    if @request.update(status: 'completed', archived: true)
      render json: { message: 'Request marked as completed and archived successfully.' }, status: :ok
    else
      render json: @request.errors, status: :unprocessable_entity
    end
  end

  def republish
    if can_be_republished?(@request)
      @request.update(last_published_at: Time.current, volunteer_count: 0, fulfilled: false)
      render json: { message: "Request republished successfully." }, status: :ok
    else
      render json: { error: "Request cannot be republished." }, status: :forbidden
    end
  end

  def all_active_requests
    active_requests = Request.where(status: 'active', archived: false).where(hidden: false)
    render json: active_requests
  end

  def update
    if @request.update(request_params)
      render json: @request, status: :ok
    else
      render json: @request.errors, status: :unprocessable_entity
    end
  end

  def volunteer
    ActiveRecord::Base.transaction do
      if @request.nil?
        render json: { error: "Request not found" }, status: :not_found
        raise ActiveRecord::Rollback
      end

      if @request.user_id == current_user.id
        render json: { error: "You cannot volunteer for your own request." }, status: :forbidden
        raise ActiveRecord::Rollback
      end

      volunteering = Volunteering.new(
        user_id: current_user.id,
        volunteereable: @request
      )

      if volunteering.save
        @request.increment!(:volunteer_count)
        if @request.volunteer_count >= 5
          @request.update!(hidden: true)
        end

        message_to_requester = @request.messages.create(
          sender_id: current_user.id,
          receiver_id: @request.user_id,
          content: "I've volunteered to help with your request: #{@request.title}."
        )
        
        message_to_volunteer = @request.messages.create(
          sender_id: @request.user_id,
          receiver_id: current_user.id,
          content: "Thank you for volunteering. The requester has been notified."
        )

        unless message_to_requester.persisted? && message_to_volunteer.persisted?
          render json: { error: "Failed to send initial messages." }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end

        render json: { message: "You have successfully volunteered. Initial messages have been sent." }, status: :ok
      else
        render json: { error: volunteering.errors.full_messages.to_sentence }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def unfulfilled_count
    count = Request.where(fulfilled: false, archived: false).count
    render json: { unfulfilled_count: count }
  end

def republish
  if @request.hidden && can_be_republished?(@request)
    ActiveRecord::Base.transaction do
      # Remove existing volunteerings for the request
      @request.volunteerings.destroy_all

      # Reset volunteer_count and other necessary fields
      @request.update(
        hidden: false,
        last_published_at: Time.current,
        volunteer_count: 0,
        fulfilled: false
      )

      render json: { message: "Request republished successfully." }, status: :ok
    end
  else
    render json: { error: "Request cannot be republished. It must be hidden, and either the volunteer count be less than or equal to 5, or at least 24 hours must have passed since the last publication." }, status: :forbidden
  end
end


  private

  def request_params
    params.require(:request).permit(:title, :description, :location, :date, :time, :taskType, :latitude, :longitude)
  end

  def set_request
    @request = Request.find_by(id: params[:id])
    Rails.logger.debug { "Request found: #{@request.inspect}" }
  end

  def can_be_republished?(request)
    Rails.logger.info "Checking republish conditions: Fulfilled:   #{request.fulfilled}, Volunteer Count: #{request.  volunteer_count}, Hours since last published: #{(Time.  current - request.last_published_at) / 1.hour} hours"
    !request.fulfilled && (request.volunteer_count <= 5 || (Time.  current - request.last_published_at) >= 24.hours)
  end
  end



