ActiveAdmin.register Font do
  permit_params do
    params = [:name, :url, :global, :organization_ids => []]
    params.push :files if (@_params["font"] && @_params["font"]["files"] && @_params["font"]["files"].match(/\[.*\]/))
    params
  end
  
  menu parent: 'Settings', priority: 3

  index do
    selectable_column
    id_column
    column :name
    column :global
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      f.input :name
      f.input :global
    end
    panel "URL and Files" do
      inputs do
        f.input :url
        f.input :files, as: :string
      end
    end
    panel "List of Organizations" do
      inputs do
        f.input :organizations
      end
    end
    actions
  end
  
  show do |v|
    attributes_table do
      row :id
      row :name
      row :global
      row :created_at
      row :updated_at
    end

    panel "Organizations" do
      table_for v.organizations do |c|
        column :id
        column :name
        column 'Actions' do |o|
          link_to('Show', admin_organization_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_organization_path(o), :class => "member_link")
        end
      end
    end
  end

  filter :name
  filter :global
  filter :created_at
  filter :updated_at
  
end
