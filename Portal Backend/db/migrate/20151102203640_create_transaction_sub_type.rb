class CreateTransactionSubType < ActiveRecord::Migration
  def change
    create_table :financial_transaction_sub_types do |t|
      t.string :name, index: true
      t.text :description
      
      t.timestamps null: false
    end
    
    add_column :financial_transactions, :financial_transaction_sub_type_id, :integer, :index => true
  end
end
