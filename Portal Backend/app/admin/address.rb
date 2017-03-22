ActiveAdmin.register Address do
  belongs_to :organization
  permit_params :label, :organization_name, :address1, :address2, :city, :state, :zip_code, :country, :organization_id, :primary, :contact_id

  index do
    selectable_column
    id_column
    column :label
    column :primary
    column :contact
    column :organization_name
    column :city
    column :state
    column :country
    column :updated_at
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :organization, :input_html => { :disabled => true } 
      input :label
      input :primary, :label => "Primary address?",:wrapper_html => {:style => 'min-height: 40px;' }
      input :contact, :collection => (f.object.organization.contacts).map { |i| [ "#{i.full_name}", "#{i.id}"] }
      if f.object.organization_name.present?
        input :organization_name
      else
        input :organization_name, :input_html => { :value => f.object.organization.name }
      end
      input :address1
      input :address2
      input :city
      input :state
      input :zip_code
      input :country, priority_countries: ["US", "Canada"]
    end
    actions
  end

  show do
    attributes_table do
      row :organization
      row :label
      row ("Primary address?") { |addr| addr.primary }
      row :organization_name
      row :contact
      row :address1
      row :address2
      row :city
      row :state
      row :zip_code
      row :country
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  filter :label
  filter :primary
  # filter :contact, :collection => Contact.all.collect {|c| ["#{c.full_name}", c.id]}
  filter :organization_name
  filter :address1
  filter :address2
  filter :city
  filter :state
  filter :zip_code
  filter :country
  filter :created_at
  filter :updated_at

end
