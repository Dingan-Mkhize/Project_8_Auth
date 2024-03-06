class CreateVolunteerings < ActiveRecord::Migration[7.0]
  def change
    create_table :volunteerings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :volunteereable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
