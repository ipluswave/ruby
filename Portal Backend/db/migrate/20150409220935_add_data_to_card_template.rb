class AddDataToCardTemplate < ActiveRecord::Migration
  def change
    add_column :card_templates, :data, :text, :default => ""
  end
end
