class AddArchivedToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :archived, :boolean
  end
end
