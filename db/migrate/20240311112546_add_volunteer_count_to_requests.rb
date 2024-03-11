class AddVolunteerCountToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :volunteer_count, :integer, default: 0
  end
end
