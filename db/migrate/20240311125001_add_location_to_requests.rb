class AddLocationToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :latitude, :float
    add_column :requests, :longitude, :float
  end
end
