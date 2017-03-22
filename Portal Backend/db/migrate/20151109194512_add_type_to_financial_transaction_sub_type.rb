class AddTypeToFinancialTransactionSubType < ActiveRecord::Migration
  def change
    create_table :financial_transaction_types do |t|
      t.integer :transaction_type, index: true
      t.string :name
    end

    # TODO (HR): I will keep it this column in the DB and remove it later when this
    # feature is matured enough
    # remove_column :financial_transactions, :operation_cd, :integer
    add_column :financial_transaction_sub_types, :financial_transaction_type_id, :integer, :default => 0
  end

end
