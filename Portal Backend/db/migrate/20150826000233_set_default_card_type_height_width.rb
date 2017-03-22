class SetDefaultCardTypeHeightWidth < ActiveRecord::Migration
  def change
    change_column :card_types, :width, :float, :default => 457
    change_column :card_types, :height, :float, :default => 288
  end
end
