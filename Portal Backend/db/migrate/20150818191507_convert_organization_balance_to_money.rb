class ConvertOrganizationBalanceToMoney < ActiveRecord::Migration
  def change
    remove_column :organizations, :balance, :integer
    change_table :organizations do |t|
      t.money :balance, :default => 0
    end
    
    remove_column :transactions, :value, :integer
    change_table :transactions do |t|
      t.money :value, :default => 0
    end
  end
end
