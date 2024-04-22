class CheckRequestFulfillmentJob < ApplicationJob
  queue_as :default

  def perform(request_id)
    request = Request.find_by(id: request_id)
    return unless request
    Rails.logger.info "CheckRequestFulfillmentJob: Processing request #{request_id}"

    if request.status == 'active'
      if request.volunteer_count == 5
        if request.update(status: 'fulfilled', fulfilled: true)
          Rails.logger.info "Request #{request_id} updated to fulfilled."
        else
          Rails.logger.error "CheckRequestFulfillmentJob: Failed to update request #{request_id} to fulfilled: #{request.errors.full_messages.join(', ')}"
        end
      elsif Time.current > request.created_at + 24.hours
        if request.update(unfulfilled: true)
          Rails.logger.info "CheckRequestFulfillmentJob: Request #{request_id} marked unfulfilled."
        else
          Rails.logger.error "CheckRequestFulfillmentJob: Failed to mark request #{request_id} as unfulfilled: #{request.errors.full_messages.join(', ')}"
        end
      else
        Rails.logger.info "CheckRequestFulfillmentJob: Request #{request_id} does not meet the fulfillment or unfulfillment criteria."
      end
    else
      Rails.logger.info "CheckRequestFulfillmentJob: Request #{request_id} is not in the 'new' state. No action taken."
    end
  end
end

