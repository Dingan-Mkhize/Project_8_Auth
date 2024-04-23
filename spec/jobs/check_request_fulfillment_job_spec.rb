# spec/jobs/check_request_fulfillment_job_spec.rb
require 'rails_helper'

RSpec.describe CheckRequestFulfillmentJob, type: :job do
  describe "time-sensitive request handling" do
    it "marks the request as unfulfilled after 24 hours" do
      request = FactoryBot.create(:request, status: 'active', last_published_at: Time.current)
      Timecop.travel(Time.current + 25.hours) do
        described_class.perform_now(request.id)
        request.reload
        expect(request.status).to eq('unfulfilled')
      end
    end
  end
end