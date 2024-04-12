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

#   def mark_as_completed
#     Rails.logger.info "Received request to mark volunteering with ID #{params[:id]} as completed"

#     volunteering = Volunteering.find_by(id: params[:id])
#     return head(:not_found) unless volunteering

#     Rails.logger.info "User #{current_user.id} attempting to mark volunteering #{volunteering.id} as completed."

#     Rails.logger.info "Checking if user #{current_user.id} is the volunteer for volunteering #{volunteering.id}"
#     unless volunteering.user == current_user
#       Rails.logger.info "User #{current_user.id} is not authorized to mark volunteering #{volunteering.id} as completed."
#       return render json: { error: "Unauthorized" }, status: :unauthorized
#     end

#   if volunteering.completed
#     render json: { error: 'This volunteering has already been marked as completed.' }, status: :unprocessable_entity
#   else
#     if volunteering.update(completed: true)
#       render json: { message: 'Volunteering marked as completed successfully.' }, status: :ok
#     else
#       render json: { errors: volunteering.errors.full_messages }, status: :unprocessable_entity
#     end
#   end
# end

  # Add any additional actions or methods required for the controller below...
end
