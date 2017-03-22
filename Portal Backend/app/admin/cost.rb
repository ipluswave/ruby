ActiveAdmin.register Cost do
  permit_params :value, :range_low, :range_high, :costable_item, :organization_id
  menu parent: 'Settings', priority: 5

  config.sort_order = 'organization_id_desc'
  
  controller do
    def index
      if params["q"].present? and params["q"]["costable_id_eq"].present? and params["q"]["costable_id_eq"].match(/-/).present?
        type,id = params["q"]["costable_id_eq"].split("-")
        params["q"]["costable_id_eq"] = id
        params["q"]["costable_type_eq"] = type
      end
      super
    end
  end

  index do
    selectable_column
    column :cost_entity
    column :organization, :sortable => 'organization_id'
    column 'Associated item', :costable_item_label
    column :range_low
    column :range_high
    column (:value) { |t| number_to_currency(t.value, negative_format: "(%u%n)") }
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :cost_entity
      row :organization
      row 'Associated item' do
        cost.costable_item_label
      end
      row :range_low
      row :range_high
      row (:value) { |t| number_to_currency(t.value, negative_format: "(%u%n)") }
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
  
  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :organization
      input :costable_item, :label => 'Associated item', :as => :select, :collection => (Cost.all_cost_items).map { |i| [ "#{i.class.to_s} - #{i.name}", "#{i.class.to_s}-#{i.id}"] }
      input :range_low
      input :range_high
      input :value, :as => :string
    end
    actions
  end
  
  filter :costable, :collection => Cost.all_cost_items.map{ |i| ["#{i.class.to_s} - #{i.name}", "#{i.class.to_s}-#{i.id}"]}, label: 'Associated item'
  filter :costable_type_cont, as: :string, label: 'Cost item name'
  filter :organization_name_cont, as: :string, label: 'Organization Name'
  filter :organization
  filter :organization_id_null, as: :select, label: "Cost Entity", collection: [['Default', true], ['Organization based', false]]
  filter :range_low
  filter :range_high
  filter :created_at
  filter :updated_at

end
