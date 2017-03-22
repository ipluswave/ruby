ActiveAdmin.register FinancialTransactionSubType do
  permit_params :id, :name, :description, :financial_transaction_type_id
  menu parent: 'Settings', priority: 12

  controller do
    def scoped_collection
      super.includes :financial_transaction_type
    end
  end

  index do
    selectable_column
    id_column
    column :financial_transaction_type
    column :name
    column :created_at
    column :updated_at
    actions
  end
  
  filter :name
  filter :description
  filter :created_at
  filter :updated_at
end
