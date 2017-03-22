class AddIndexForPreview < ActiveRecord::Migration
  def change
    add_index :users, :pin
  end
end
