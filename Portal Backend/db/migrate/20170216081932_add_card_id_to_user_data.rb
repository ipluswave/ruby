class AddCardIdToUserData < ActiveRecord::Migration
  def change
    add_column :user_data, :card_id, :integer
    add_index :user_data, :card_id
  end
end
