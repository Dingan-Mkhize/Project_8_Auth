class AddLastPublishedAtAndFulfilledToRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :requests, :last_published_at, :datetime
    add_column :requests, :fulfilled, :boolean, default: false
  end
end
