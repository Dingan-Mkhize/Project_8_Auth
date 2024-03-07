class AddTitleToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :title, :string
  end
end
