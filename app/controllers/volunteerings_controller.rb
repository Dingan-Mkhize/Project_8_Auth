class VolunteeringsController < ApplicationController
  before_action :authenticate_user!, only: [:volunteered_jobs]

  def volunteered_jobs
    # This assumes a volunteering relationship exists and is set up correctly
    volunteerings = current_user.volunteerings.includes(:volunteereable).map(&:volunteereable)
    render json: volunteerings
  end

  def mark_as_completed
  volunteering = Volunteering.find(params[:id])
  return head(:not_found) unless volunteering

  if volunteering.update(completed: true)
    render json: { message: 'Volunteering marked as completed successfully.' }, status: :ok
  else
    render json: { errors: volunteering.errors.full_messages }, status: :unprocessable_entity
  end
end
end