class RenameMoneyTransacation < ActiveRecord::Migration
  def change
    rename_table :money_transactions, :financial_transactions
    rename_column :transaction_items, :money_transaction_id, :financial_transaction_id
  end
end
