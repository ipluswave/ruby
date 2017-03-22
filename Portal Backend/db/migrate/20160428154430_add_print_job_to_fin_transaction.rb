class AddPrintJobToFinTransaction < ActiveRecord::Migration
  def change
    add_column :financial_transactions, :print_job_id, :integer, :default => nil
    add_index :financial_transactions, :financial_transaction_sub_type_id, name: "financial_transaction_sub_type_id"
    
    FinancialTransaction.where(financial_transaction_sub_type_id: 4).find_each(batch_size: 5000) do |ft|
      res = ft.description.match(/Print Job ID ([0-9]+)/)
      if res
        ft.print_job_id = res[1].to_i
        ft.save!
        next
      end
    end
  end
end
