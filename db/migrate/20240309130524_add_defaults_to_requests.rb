class AddDefaultsToRequests < ActiveRecord::Migration[7.0]
  def up
    change_column :requests, :status, :string, default: 'active'
    change_column :requests, :archived, :boolean, default: false
  end

  def down
    change_column :requests, :status, :string, default: nil
    change_column :requests, :archived, :boolean, default: nil
  end
end
