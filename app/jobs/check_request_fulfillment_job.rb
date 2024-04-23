class CheckRequestFulfillmentJob < ApplicationJob
  queue_as :default

  def perform(request_id)
    request = Request.find_by(id: request_id)
    return unless request
    Rails.logger.info "CheckRequestFulfillmentJob: Processing request #{request_id}"

    if request.status == 'active'
      if request.volunteer_count >= 5
        update_request_to_fulfilled(request)
      elsif Time.current > (request.last_published_at + 24.hours)
        update_request_to_unfulfilled(request)
      else
        Rails.logger.info "CheckRequestFulfillmentJob: Request #{request_id} does not meet the fulfillment or unfulfillment criteria."
      end
    else
      Rails.logger.info "CheckRequestFulfillmentJob: Request #{request_id} is not in the 'active' state. No action taken."
    end
  end

  private

  def update_request_to_fulfilled(request)
    if request.update(status: 'fulfilled', fulfilled: true)
      Rails.logger.info "Request #{request.id} updated to fulfilled."
    else
      Rails.logger.error "Failed to update request #{request.id} to fulfilled: #{request.errors.full_messages.join(', ')}"
    end
  end

  def update_request_to_unfulfilled(request)
    if request.update(unfulfilled: true, status: 'unfulfilled')
      Rails.logger.info "Request #{request.id} marked unfulfilled."
    else
      Rails.logger.error "Failed to mark request #{request.id} as unfulfilled: #{request.errors.full_messages.join(', ')}"
    end
  end
end


