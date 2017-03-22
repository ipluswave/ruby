class ChangeCostValueToMoney < ActiveRecord::Migration
  def change
    change_column :costs, :value, :money
  end
end
