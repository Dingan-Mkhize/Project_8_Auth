class AddCompletedToVolunteerings < ActiveRecord::Migration[7.0]
  def change
    add_column :volunteerings, :completed, :boolean, default: false
  end
end
