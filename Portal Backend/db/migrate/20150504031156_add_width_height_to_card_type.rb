class AddWidthHeightToCardType < ActiveRecord::Migration
  def change
    add_column :card_types, :width, :float, :default => 0
    add_column :card_types, :height, :float, :default => 0
  end
end
