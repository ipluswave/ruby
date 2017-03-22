class AddCardDataToCardTemplate < ActiveRecord::Migration
  def change
    add_column :card_templates, :card_data, :json, :default => []
  end
end
