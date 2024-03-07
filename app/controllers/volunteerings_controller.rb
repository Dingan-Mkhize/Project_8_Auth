class VolunteeringsController < ApplicationController
  before_action :authenticate_user!, only: [:volunteered_jobs]

  def volunteered_jobs
    # This assumes a volunteering relationship exists and is set up correctly
    volunteerings = current_user.volunteerings.includes(:volunteereable).map(&:volunteereable)
    render json: volunteerings
  end
end