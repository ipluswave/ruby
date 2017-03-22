class AddRangeToCosts < ActiveRecord::Migration
  def change
    remove_column :costs, :quantity, :integer
    add_column :costs, :range_low, :integer, :default => 0
    add_column :costs, :range_high, :integer, :default => 0
  end
end
