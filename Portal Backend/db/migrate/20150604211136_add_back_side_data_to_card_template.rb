class AddBackSideDataToCardTemplate < ActiveRecord::Migration
  def change
    add_column :card_templates, :back_data, :text, :default => ""
    rename_column :card_templates, :data, :front_data
  end
end
