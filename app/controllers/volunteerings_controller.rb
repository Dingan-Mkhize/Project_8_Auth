class VolunteeringsController < ApplicationController
  before_action :authenticate_user!, only: [:volunteered_jobs, :mark_as_completed]

  def volunteered_jobs
    # Since volunteers don't mark jobs as completed, 
    # you may want to include additional checks or data, 
    # such as whether the job is still active.
    volunteerings = current_user.volunteerings.includes(:volunteereable).map do |volunteering|
      {
        id: volunteering.volunteereable_id,
        title: volunteering.volunteereable.title,
        description: volunteering.volunteereable.description,
        location: volunteering.volunteereable.location,
        date: volunteering.volunteereable.date,
        time: volunteering.volunteereable.time,
        status: volunteering.volunteereable.status,
        # Add other fields as necessary
      }
    end
    render json: volunteerings
  end

  # Add any additional actions or methods required for the controller below...
end
