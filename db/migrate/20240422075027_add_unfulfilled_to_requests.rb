class AddUnfulfilledToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :unfulfilled, :boolean, default: false
  end
end
