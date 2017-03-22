ActiveAdmin.register MigrationTask do
  permit_params :user_id, :from_organization_id, :to_organization_id, :status_cd
  menu parent: 'Migrations', priority: 1

  member_action :execute, method: :put do
    resource.Running!
    resource.save!
    Jobs::MigrationTaskJob.enqueue({migration_task_id: resource.id})
    redirect_to admin_migration_task_path, notice: "Migration Job sent for workers!"
  end
  
  action_item :execute, only: :show do
    link_to("Execute", execute_admin_migration_task_path(migration_task), :class => "member_link", method: :put) if migration_task.Created?
  end

  index do
    selectable_column
    id_column
    column :status
    column :from_organization_id
    column :to_organization_id
    column :total_migrated
    column :created_at
    column :updated_at
    column 'Created by', :user

    column 'Execute' do |c|
      if c.Created?
        link_to("Execute", execute_admin_migration_task_path(c), :class => "member_link", method: :put)
      end
    end

    actions
  end

  show do |o|
    attributes_table do
      row :id
      row :user
      row :from_organization_id
      row :to_organization_id
      row :status
      row :total_migrated
      row :created_at
      row :updated_at
    end

    panel "Organizations migrated" do
      table_for o.organizations do |c|
        column :id
        column :name
        column :system, :sortable => :system_cd do |o|
          case o.system
          when :Legacy
            status_tag( 'Legacy', :red )
          when :NewSystem
            status_tag( 'New System', :ok )
          else
            status_tag( 'Not Provided', :yellow )
          end
        end
        column :status, :sortable => :status_cd do |o|
          case o.status
          when :Active
            status_tag( 'Active', :ok )
          when :Inactive
            status_tag( 'Inactive', :yellow )
          else
            status_tag( 'Not Provided', :red )
          end
        end
        column :migration_status, :sortable => :migration_status_cd do |o|
          case o.migration_status
          when :migration_ok
            status_tag( 'Ok', :ok )
          when :migration_warning
            status_tag( 'Warning', :yellow )
          when :migration_error
            status_tag( 'Error', :red )
          when :migration_undefined
            status_tag( 'Undefined', :red )
          end
        end
        column :created_at
        column 'Actions' do |o|
          link_to('Show', admin_organization_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_organization_path(o), :class => "member_link")
        end
      end
    end

    panel "Log messages" do
      table_for o.migration_logs do |c|
        column :organization
        column :status, :sortable => :status_cd do |o|
          case o.status
          when :migration_log_ok
            status_tag( 'Ok', :ok )
          when :migration_log_warning
            status_tag( 'Warning', :yellow )
          when :migration_log_error
            status_tag( 'Error', :red )
          else
            status_tag( 'Unknown', :red )
          end
        end

        column :long_message
        column :created_at
        column 'Actions' do |o|
          link_to('Show', admin_migration_log_path(o), :class => "member_link")
        end
      end
    end

    active_admin_comments
    if o.Running?
      render partial: "layouts/reload"
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :from_organization_id, :label => 'From Organization ID'
      input :to_organization_id, :label => 'To Organization ID'
      input :user_id, :input_html => { :value => current_user.id }, as: :hidden
    end
    actions
  end


  filter :from_organization_id
  filter :to_organization_id
  filter :status_cd, as: :select, collection: proc { MigrationTask.statuses.hash }, label: 'Status'
  filter :created_at
  filter :updated_at

end
