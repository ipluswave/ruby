ActiveAdmin.register SpecialHandling do
  permit_params :name, :description, :token, :organization_id
  menu parent: 'Settings', priority: 7

  index do
    selectable_column
    id_column
    column :name
    column :organization
    column :token
    column :description
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :organization
      row :token
      row :description
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :name
      input :organization
      input :token
      input :description
    end
    actions
  end

  filter :name
  filter :description
  filter :token
  filter :organization
  filter :card_templates_name_cont, as: :string, label: 'Card Template Name'
  # filter :card_templates
  filter :created_at
  filter :updated_at
  
end
