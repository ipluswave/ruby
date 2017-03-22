ActiveAdmin.register Workstation do
  permit_params :name, :site_id, :workers_queue, :status_cd
  menu parent: 'Print Locations', priority: 2

  scope :all
  scope "Active", :workstation_is_active, default: true

  controller do
    def scoped_collection
      super.includes :site
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :site
    column :status, :sortable => :status_cd do |o|
      case o.status
        when :Inactive
          status_tag( 'Inactive', :red )
        when :Active
          status_tag( 'Active', :ok )
        else
          status_tag( 'Out of commission', :yellow )
      end
    end
    column :created_at
    column :updated_at
    actions
  end

  show do |ct|
    attributes_table do
      row :id
      row :name
      row :site
      row :workers_queue
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      f.input :name
      f.input :site
      f.input :workers_queue
      f.input :status_cd, :label => 'Status', :as => :select, :collection => Workstation.statuses.hash, include_blank: false
    end
    actions
  end

  filter :status_cd, as: :select, collection: proc { Workstation.statuses.hash }, label: 'Status'
end
