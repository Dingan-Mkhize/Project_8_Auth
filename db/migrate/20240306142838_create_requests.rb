class CreateRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :requests do |t|
      t.string :description
      t.string :type
      t.string :status
      t.string :location
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
