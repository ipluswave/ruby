class MigrationNewAttributes < ActiveRecord::Migration
  def change
    add_column :organizations, :migration_status_cd, :integer
    add_column :organizations, :last_financial_transaction, :datetime
    
    Organization.all.each do |org|
      ft = org.financial_transactions.last
      if ft.present?
        org.last_financial_transaction = ft.created_at
        org.save
      end
    end
  end
end
