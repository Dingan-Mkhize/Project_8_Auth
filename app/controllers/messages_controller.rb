class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    request = Request.find(params[:request_id])
    messages = request.messages.order(created_at: :asc)
    render json: messages.as_json(include: { sender: { only: [:id, :name, :email] } })
  end

  def create
    message = Message.new(message_params)
    message.sender = current_user
    message.request = Request.find(params[:request_id])

    if message.save
      render json: message.as_json(include: { sender: { only: [:id, :name, :email] } }), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :receiver_id)
  end
end