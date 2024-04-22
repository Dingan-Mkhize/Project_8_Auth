class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
  request = Request.find(params[:request_id])
  messages = request.messages.includes(:sender).order(created_at: :asc)
  render json: messages.as_json(include: { sender: { methods: [:full_name], only: [:id] } })
end

def create
  message = current_user.sent_messages.build(message_params.merge(request_id: params[:request_id]))
  message.timestamp = Time.now
  if message.save
    handle_special_message_content(message)
    render json: message.as_json(include: { sender: { methods: [:full_name], only: [:id] } }), status: :created
  else
    render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
  end
end


  private

  def message_params
    # Ensure you're permitting receiver_id and content for the message
    params.require(:message).permit(:content, :receiver_id)
  end

  def handle_special_message_content(message)
    if message.content.include?('completed')
      volunteering = Volunteering.find_by(user_id: message.sender_id, volunteereable_id: message.request_id, volunteereable_type: 'Request')
      volunteering.update(completed: true) if volunteering
    end
  end
end
