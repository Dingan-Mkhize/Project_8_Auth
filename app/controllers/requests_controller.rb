class RequestsController < ApplicationController
  before_action :authenticate_user!, only: [:index, :create, :show, :mark_as_completed, :republish, :update, :volunteer]
  before_action :set_request, only: [:show, :mark_as_completed, :republish, :update, :volunteer]

  def index
    own_requests = current_user.requests.where(archived: false)
    volunteered_requests = Request.joins(:volunteerings)
                                  .where(volunteerings: { user_id: current_user.id }, archived: false)

    combined_requests = (own_requests + volunteered_requests).uniq
    render json: combined_requests.as_json(only: [:id, :title], include: {user: { only: [:id, :first_name, :last_name]}})
  end

  def create
    new_request_params = request_params.merge({
      user_id: current_user.id, # Assuming `current_user` returns the user creating the request
      archived: false,
      status: 'active',
      last_published_at: Time.current,
      volunteer_count: 0,
      fulfilled: false,
      hidden: false
    })
    request = Request.new(new_request_params)
    if request.save
      CheckRequestFulfillmentJob.set(wait: 24.hours).perform_later(request.id) 
      render json: request, status: :created
    else
      render json: request.errors, status: :unprocessable_entity
    end
  end

    def show
  @request_owner = User.find(@request.user_id)
  @user_volunteered = User.joins(:volunteerings)
                          .where(volunteerings: { volunteereable_id: @request.id, volunteereable_type: 'Request' })
                          .where(id: current_user.id)
                          .exists?

  # Allow access to fulfilled or archived requests if the user is the requester or a volunteer
  if (@request.fulfilled? || @request.archived?) && !(@user_volunteered || current_user == @request_owner)
    render json: { error: "Access denied" }, status: :forbidden
    return
  end

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
      isRequester: current_user == @request_owner,
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
    if current_user != @request.user
      render json: { error: "Only the requester can mark the request as completed." }, status: :forbidden
      return
    end

    if @request.update(status: :completed, archived: true, fulfilled: true)
      # After updating the status to completed, you may also want to handle related logic,
      # such as notifying involved parties or logging the event.
      render json: { message: 'Request marked as completed and archived successfully.' }, status: :ok
    else
      render json: @request.errors, status: :unprocessable_entity
    end
  end

  def republish
    if current_user != @request.user
      render json: { error: "Only the requester can republish their own request." }, status: :forbidden
      return
    end

    if can_be_republished?(@request)
      ActiveRecord::Base.transaction do
        @request.volunteerings.destroy_all
        @request.update(
          status: :active,
          hidden: false,
          last_published_at: Time.current,
          volunteer_count: 0,
          fulfilled: false
        )
        CheckRequestFulfillmentJob.set(wait: 24.hours).perform_later(@request.id)
        render json: { message: "Request republished successfully." }, status: :ok
      end
    else
      render json: { error: "Request cannot be republished. It must be hidden, and either the volunteer count must be less than or equal to 5, or at least 24 hours must have passed since the last publication." }, status: :forbidden
    end
  end

  def all_active_requests
    include_timed_out = params[:includeTimedOut].present? && params[:includeTimedOut] == 'true'

    if include_timed_out
      Rails.logger.info "Fetching active requests including timed out requests"
      active_requests = Request.where(status: 'active', archived: false)
    else
      Rails.logger.info "Fetching active requests excluding timed out requests"
      active_requests = Request.where(status: 'active', archived: false, hidden: false)
    end

    Rails.logger.info "Active requests count: #{active_requests.count}"
    Rails.logger.debug "Active requests: #{active_requests.to_a}"

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
        Rails.logger.info "Executing CheckRequestFulfillmentJob for request #{@request.id}"
        CheckRequestFulfillmentJob.perform_now(@request.id)
        Rails.logger.info "CheckRequestFulfillmentJob executed for request #{@request.id}"


        message_to_requester = @request.messages.create(
          sender_id: current_user.id,
          receiver_id: @request.user_id,
          content: "I've volunteered to help with your request: #{@request.title}."
        )
        
        message_to_volunteer = @request.messages.create(
          sender_id: @request.user_id,
          receiver_id: current_user.id,
          content: "Thank you for volunteering. I look forward to working with you."
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
    count = Request.where(fulfilled: false, archived: false, hidden: false).count
    render json: { unfulfilled_count: count }
  end

  def republish
    if @request.hidden && can_be_republished?(@request)
      ActiveRecord::Base.transaction do
        # Remove existing volunteerings for the request
        @request.volunteerings.destroy_all

        # Reset volunteer_count and other necessary fields
        @request.update(
          status: 'active',
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

  # New methods added

  def active_requests
    active_requests = Request.where(status: 'active', archived: false, hidden: false)
    render json: active_requests
  end

  def fulfilled_requests
    fulfilled_requests = Request.where(fulfilled: true, archived: false)
    render json: fulfilled_requests
  end

  def unfulfilled_requests
    unfulfilled_requests = Request.where(unfulfilled: true, archived: false)
    render json: unfulfilled_requests
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
    Rails.logger.info "Checking republish conditions: Fulfilled:   #{request.fulfilled}, Volunteer Count: #{request.volunteer_count}, Hours since last published: #{(Time.current - request.last_published_at) / 1.hour} hours"
    !request.fulfilled && (request.volunteer_count <= 5 || (Time.current - request.last_published_at) >= 24.hours)
  end
end



