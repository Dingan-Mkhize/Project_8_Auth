class AddArchivedToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :archived, :boolean, default: false, null: false
    add_index :messages, :archived
  end
end
