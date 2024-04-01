class RequestsController < ApplicationController
  before_action :authenticate_user!, only: [:index, :create, :show, :mark_as_completed, :republish, :update]
  before_action :set_request, only: [:show, :mark_as_completed, :republish, :update, :volunteer]

  def index
    own_requests = current_user.requests.where(archived: false)
    
    volunteered_requests = Request.joins(:volunteerings)
                                .where(volunteerings: { user_id: current_user.id })
                                .where(archived: false)

    combined_requests = (own_requests + volunteered_requests).uniq

    render json: combined_requests.as_json(only: [:id, :title])
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
  is_requester = @request.user == current_user
  volunteers_info = @request.volunteers.select(:id, "first_name || ' ' || last_name AS name").as_json

  # Filter messages so users only see the ones relevant to them
  messages_info = if current_user.id == @request.user_id
                    # If the user is the requester, they see all messages
                    @request.messages.order(created_at: :asc)
                  else
                    # If the user is not the requester, they only see messages where they are the sender or receiver
                    @request.messages.where("sender_id = ? OR receiver_id = ?", current_user.id, current_user.id).order(created_at: :asc)
                  end

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

  def volunteer
  ActiveRecord::Base.transaction do
    if @request.nil?
      render json: { error: "Request not found" }, status: :not_found
      raise ActiveRecord::Rollback
    end

    # Prevent users from volunteering for their own requests
    if @request.user_id == current_user.id
      render json: { error: "You cannot volunteer for your own request." }, status: :forbidden
      raise ActiveRecord::Rollback
    else
      volunteering = Volunteering.new(
        user_id: current_user.id,
        volunteereable: @request
      )

      if volunteering.save
        @request.increment!(:volunteer_count)
        if @request.volunteer_count >= 5
          @request.update(hidden: true)
        end

        # Message to the requester
        message_to_requester = Message.create(
          request_id: @request.id,
          sender_id: current_user.id,
          receiver_id: @request.user_id,
          content: "I've volunteered to help with your request: #{@request.title}. Looking forward to working together!"
        )

        # Message to the volunteer
        message_to_volunteer = Message.create(
          request_id: @request.id,
          sender_id: @request.user_id, # Assuming the system or the requester as the sender
          receiver_id: current_user.id,
          content: "Thank you for volunteering to help with #{@request.title}. The requester has been notified, and you can start communicating directly through this chat."
        )

        unless message_to_requester.persisted? && message_to_volunteer.persisted?
          render json: { error: "Failed to send initial messages." }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end

        # Successfully created the volunteering record and the messages
        render json: { message: "You have successfully volunteered. Initial messages have been sent to both you and the requester." }, status: :ok
      else
        # Failed to create the volunteering record
        render json: { error: volunteering.errors.full_messages.to_sentence }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end
end

def unfulfilled_count
    count = Request.where(fulfilled: false, archived: false).count
    render json: { unfulfilled_count: count }
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
    !request.fulfilled && request.volunteer_count < 5 && (Time.current - request.last_published_at) > 24.hours
  end
end


