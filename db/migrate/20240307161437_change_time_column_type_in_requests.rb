class ChangeTimeColumnTypeInRequests < ActiveRecord::Migration[7.0]
  def up
    # Ensure the format in the USING clause matches the format of your time strings
    change_column :requests, :time, 'time USING CAST(time AS time)'
  end

  def down
    change_column :requests, :time, :string
  end
end
