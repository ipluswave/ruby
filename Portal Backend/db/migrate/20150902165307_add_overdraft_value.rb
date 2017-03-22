class AddOverdraftValue < ActiveRecord::Migration
  def change
    add_column :organizations, :overdraft, :money, :default => 25.0
    add_column :transactions, :balance, :money, :default => 0
  end
end
