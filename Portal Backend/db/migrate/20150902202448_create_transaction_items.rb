class CreateTransactionItems < ActiveRecord::Migration
  def change
    rename_table :transactions, :money_transactions
    create_table :transaction_items do |t|
      t.integer :total
      t.money :value
      t.references :money_transaction
      t.references :cost
      t.timestamps
    end
  end
end
