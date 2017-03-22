ActiveAdmin.register Contact do
  belongs_to :organization
  permit_params :full_name, :phone_number, :alt_phone_number, :fax_number, :email, :alt_email

  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :phone_number
    column :updated_at
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :organization, :input_html => { :disabled => true } 
      input :full_name
      input :email
      input :alt_email
      input :phone_number
      input :alt_phone_number
      input :fax_number
    end
    actions
  end
  
  show do
    attributes_table do
      row :organization
      row :full_name
      row :email
      row :alt_email
      row :phone_number
      row :alt_phone_number
      row :fax_number
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  filter :full_name
  filter :email
  filter :alt_email
  filter :phone_number
  filter :alt_phone_number
  filter :fax_number
  filter :created_at
  filter :updated_at
end
