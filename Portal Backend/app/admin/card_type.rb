ActiveAdmin.register CardType do
  permit_params :name, :description, :width, :height, organization_ids: []
  menu parent: 'Settings', priority: 1

  controller do
    def scoped_collection
      super.includes :organizations
    end
  end

  show do |ct|
    attributes_table do
      row :name
      row :description
      row :width
      row :height
      row :created_at
      row :updated_at
    end

    panel "Organizations" do
      table_for ct.organizations do |org|
        column :id
        column :name
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_organization_path(o), :class => 'member_link')
        end
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :name
      input :organizations
      input :description
      input :width
      input :height
    end
    actions
  end

  filter :name
  filter :description
  filter :card_templates_name_cont, as: :string, label: 'Card Template Name'
  # filter :card_templates
  filter :organizations
  filter :printers
  filter :created_at
  filter :updated_at
  
end
