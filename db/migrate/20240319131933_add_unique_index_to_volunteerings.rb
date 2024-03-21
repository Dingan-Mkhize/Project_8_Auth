class AddUniqueIndexToVolunteerings < ActiveRecord::Migration[7.0]
  def change
    add_index :volunteerings, [:user_id, :volunteereable_id, :volunteereable_type], unique: true, name: 'index_volunteerings_on_user_and_volunteereable'
  end
end
