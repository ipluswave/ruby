ActiveAdmin.register FinancialTransaction do
  permit_params :organization_id, :user_id, :description, :operation_cd, :credit, :debit, :created_at, :financial_transaction_sub_type_id
  actions :all, :except => [:destroy]
  menu parent: 'Reports', priority: 1

  # config.sort_order = 'created_at_desc'
  config.per_page = 75

  controller do
    def new_admin_financial_transaction_path(options)
      org_id_prefix = (params["q"].present? and params["q"]["organization_id_eq"].present?) ? "?organization_id=#{params['q']['organization_id_eq']}" : ""
      super(options) + org_id_prefix
    end

    def scoped_collection
      super.includes :organization, :financial_transaction_type, :user
    end
  end
  
  action_item :org_financial_transactions, only: :show do
    link_to('Company Financial Transactions', admin_financial_transactions_path()+"?q%5Borganization_id_eq%5D=#{resource.organization_id}")
  end
  
  action_item :back_to_organization, only: :index do
    if (params.present? and params["q"].present? and params["q"]["organization_id_eq"].present?)
      link_to "Back to Organization page", admin_organization_path(params["q"]["organization_id_eq"])
    end
  end

  index do
    selectable_column
    id_column
    unless (params["q"].present? and params["q"].keys.select { |a| a.match(/organization_id_eq/) }.present?)
      column :organization
    end
    column :created_at
    column :credit, :class => "amount" do |t|
      number_to_currency(t.credit, negative_format: "(%u%n)") unless t.credit.eql?0
    end
    column :short_description
    column :debit, :class => "amount" do |t|
      number_to_currency(t.debit, negative_format: "(%u%n)") unless t.debit.eql?0
    end
    # column :operation
    column 'Type', :financial_transaction_type
    column 'Sub type' do |t|
      t.financial_transaction_sub_type.name
    end
    column :print_job
    column :balance, :class => "amount" do |t|
      number_to_currency(t.balance, negative_format: "(%u%n)")
    end 
    column 'Last changed by', :user
    actions
  end

  show do |o|
    attributes_table do
      row :id
      row :organization
      row :description
      # row :operation
      row ("Type") { |t| t.financial_transaction_type }
      row ("Sub type") { |t| t.financial_transaction_sub_type }
      row (:credit) { |t| number_to_currency(t.credit, negative_format: "(%u%n)") }
      row (:debit) { |t| number_to_currency(t.debit, negative_format: "(%u%n)") }
      row (:balance) { |t| number_to_currency(t.balance, negative_format: "(%u%n)") }
      row :created_at
      row :updated_at
    end

    panel "Items" do
      table_for o.transaction_items do |c|
        column "# of Items", :total
        column (:value) { |ti| number_to_currency(ti.value, negative_format: "(%u%n)") }
        column ("Cost Item") { |ti| (ti.cost.present? ? ti.cost.costable_item_label : "not provided") }
        column ("Cost Item unit value") { |ti| (ti.cost.present? ? number_to_currency(ti.cost.value, negative_format: "(%u%n)") : "not provided") }
        column ("Organization") { |ti| ((ti.cost.present? and ti.cost.organization_id.present?) ? link_to(ti.cost.organization.name, admin_organization_path(ti.cost.organization)) : "-Global Cost-")}
        column :created_at
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      if f.object.new_record?
        f.object.organization_id = params["organization_id"] if params["organization_id"].present?
        input :organization
      end
      input :description
      # input :operation_cd, :label => 'Operation', :as => :radio, :collection => FinancialTransaction.operations.hash if f.object.new_record?
      input :financial_transaction_sub_type, :label => 'Sub type'
      input :credit, :as => :string if f.object.new_record?
      input :debit, :as => :string if f.object.new_record?
      input :user_id, :input_html => { :value => current_user.id }, as: :hidden
      input :created_at, as: :datepicker
    end
    actions
  end
  
  csv do
    column :id
    column (:organization_identifier) { |o| o.organization.present? ? o.organization.id : "not correctly migrated" }
    column (:organization_name) { |o| o.organization.present? ? o.organization.name : "not correctly migrated" }
    column :description
    column (:financial_transaction_type) { |o| o.financial_transaction_type.present? ? o.financial_transaction_type.name : "not correctly migrated" }
    column (:financial_transaction_sub_type) { |o| o.financial_transaction_sub_type.present? ? o.financial_transaction_sub_type.name : "not correctly migrated" }
    column :credit, :class => "amount" do |t|
      number_to_currency(t.credit, negative_format: "(%u%n)")
    end 
    column :debit, :class => "amount" do |t|
      number_to_currency(t.debit, negative_format: "(%u%n)")
    end 
    column :balance, :class => "amount" do |t|
      number_to_currency(t.balance, negative_format: "(%u%n)")
    end 
    column :created_at
    column (:last_changed_by_user) { |o| o.user.present? ? o.user.email : "" }
  end

  # filter :operation_cd, as: :select, collection: proc { FinancialTransaction.operations.hash }, label: 'Operation'
  filter :organization
  filter :organization_name_cont, as: :string, label: 'Organization Name'
  filter :organization_id_gt, as: :string, label: 'From Organization ID'
  filter :organization_id_lt, as: :string, label: 'To Organization ID'
  filter :financial_transaction_type
  filter :financial_transaction_sub_type
  filter :created_at
  filter :updated_at
  
end
