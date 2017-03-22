class BreakTransactionValueInCreditDebit < ActiveRecord::Migration
  def change
    rename_column :financial_transactions, :value, :credit
    change_column :financial_transactions, :credit, :money, :default => 0.0
    add_column :financial_transactions, :debit, :money, :default => 0.0
    
    add_column :organizations, :status_cd, :integer, :default => 0
    add_index :organizations, :status_cd
  end
end
