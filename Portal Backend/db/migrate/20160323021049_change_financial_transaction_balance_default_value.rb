class ChangeFinancialTransactionBalanceDefaultValue < ActiveRecord::Migration
  def change
    change_column :financial_transactions, :balance, :money, :default => nil
  end
end
