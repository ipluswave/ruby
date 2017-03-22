ActiveAdmin.register MigrationLog do
  # permit_params :organization_id
  menu parent: 'Migrations', priority: 2
  actions :all, :except => [:new, :edit, :destroy]

  index do |o|
    column :migration_task
    column :organization
    column :organization_status do |ml|
      case ml.organization.migration_status
      when :migration_ok
        status_tag( 'Ok', :ok )
      when :migration_warning
        status_tag( 'Warning', :yellow )
      when :migration_error
        status_tag( 'Error', :red )
      when :cleared
        status_tag('Cleared')
      else
        ""
      end unless ml.organization.blank?
    end
    column :last_financial_transaction do |ml|
      time_ago_in_words(ml.organization.last_financial_transaction) if (ml.organization.present? and ml.organization.last_financial_transaction.present?)
    end
    column :message_status, :sortable => :status_cd do |o|
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
    column :short_message do |o|
      o.short_message(75)
    end
    column :created_at
    actions
  end
  
  show do |o|
    attributes_table do
      row :id
      row :migration_task
      row :organization
      row :message
      row (:status) do |o|
        case o.status
        when :migration_log_ok
          status_tag( 'Ok', :ok )
        when :migration_log_warning
          status_tag( 'Warning', :yellow )
        when :migration_log_error
          status_tag( 'Error', :red )
        else
          status_tag( 'Undefined', :red )
        end
      end
    end

    active_admin_comments
  end

  filter :organization_name_cont, as: :string, label: 'Organization Name'
  filter :organization
  filter :organization_migration_status_cd, as: :select, collection: proc {Organization.migration_statuses.hash}, lagel: 'Organization Status'
  filter :migration_task
  filter :status_cd, as: :select, collection: proc { MigrationLog.statuses.hash }, label: 'Status'
  filter :message
  filter :created_at
  filter :updated_at

end
