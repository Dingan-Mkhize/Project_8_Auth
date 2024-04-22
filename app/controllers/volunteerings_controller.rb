class VolunteeringsController < ApplicationController
  before_action :authenticate_user!, only: [:volunteered_jobs]

  def volunteered_jobs
    # Fetch only active, non-fulfilled, and non-archived volunteerings by joining with the requests table
    volunteerings = current_user.volunteerings
    .joins("INNER JOIN requests ON volunteerings.volunteereable_id = requests.id AND volunteerings.volunteereable_type = 'Request'")
    .where(requests: { archived: false })
    .select("volunteerings.*, requests.title, requests.description, requests.location, requests.date, requests.time, requests.status, requests.fulfilled")

  volunteerings_data = volunteerings.map do |volunteering|
    {
      id: volunteering.volunteereable_id,
      title: volunteering.title,
      description: volunteering.description,
      location: volunteering.location,
      date: volunteering.date,
      time: volunteering.time,
      status: volunteering.status,
      fulfilled: volunteering.fulfilled
      # Add other fields as necessary
    }
  end

    render json: volunteerings_data
  end
end