ActiveAdmin.register Organization do
  permit_params :name, :legacy_id, :overdraft, :parent_organization_id, :industry_id, :category_id, :system_cd, :status_cd, :migration_status_cd, addresses_attributes: [:label, :primary, :address1, :address2, :city, :state, :zip_code, :country], contacts_attributes: [:full_name, :email, :alt_email, :phone_number, :alt_phone_number, :fax_number], users_attributes: [:email, :pin, :role_ids => []], :settings => [:hide_balance]
  menu priority: 2
  config.per_page = 50

  scope :all, default: true
  scope "Pending", :org_is_pending
  scope "Active", :org_is_active
  scope "Dorment", :org_is_dorment
  scope "Inactive", :org_is_inactive

  action_item :setup_organization, only: :index do
    link_to "Setup an Organization", setup_organization_admin_organizations_path
  end

  batch_action :switch_to_new_system do |ids|
    Organization.where('id in (?)',ids).update_all(system_cd: 1)
    flash[:notice] = "Action performed. May the force be with you!"
    redirect_to :back
  end

  member_action :print_label, method: :put do
    begin
      PrintJob.from_organization(resource)
      redirect_to admin_organization_path(resource), notice: "Label sent to the Print Workers Queue!"
    rescue
      flash[:error] = "Organization need a card template to print a label"
      redirect_to :back #, error: "Organization need a card template to print a label"
    end
  end
  
  member_action :check_legacy_balance, method: :put do
    org = resource
    wsdl_user = org.users.first

    redir_symbol = :notice
    msg = "This feature is deprecated"
    # This code was used during the migration and right after the migration
    # [HR] Delete if not used after 06/10/2017
    # if wsdl_user.present?
    #   basic_params = { "email" => wsdl_user.email.upcase, "CompanyPIN" => wsdl_user.pin}
    #   client = Savon::Client.new(wsdl: ENV['legacy_preview_root'])
    #   wsdl_acc_balance = client.call(:acc_balance, message: basic_params)
    #   begin
    #     mres = wsdl_acc_balance.to_hash[:acc_balance_response][:return].match(/01#([\-0-9\.]+)#(.*)/)
    #     if mres
    #       legacy_balance = mres[1].to_f.round(2)
    #       unless org.balance.to_s.eql? legacy_balance.to_s
    #         redir_symbol = :error
    #         msg = "Organization balance ($#{org.balance.to_s}) is different from legacy system ($#{legacy_balance})."
    #       else
    #         redir_symbol = :notice
    #         msg = "Organization balance is the same as the legacy system!"
    #       end
    #     else
    #       redir_symbol = :warning
    #       msg = "Unable to check balance for Organization #{org.name}. Possibly auth failed for user '#{wsdl_user.email}' with '#{wsdl_user.pin}'"
    #     end
    #   rescue Exception => e
    #     # 2nd check not ok
    #     redir_symbol = :warning
    #     msg = "May the force be with you. And give Helio a slack call!"
    #     Rails.logger.info("Check balance exception: #{e.message}")
    #     Rails.logger.info(e.backtrace)
    #   end
    # else
    #   redir_symbol = :warning
    #   msg = "Organization don't have a Admin user"
    # end

    flash[redir_symbol] = msg
    redirect_to admin_organization_path(resource)
  end
  
  member_action :report_tab1, method: :get do
    org = resource
    attributes = ['Date','Company ID','Company Name']
    
    act = org.card_templates.first
    tab1_csv = attributes.to_csv
    if act.present?
      card_attributes = act.template_fields.map { |obj| obj['label'] }
      attributes += card_attributes
      attributes.delete('Portrait')
      attributes.delete('Signature')
      org_card_ids = org.card_templates.map { |ct| ct.id }
      org.child_organizations.each do |corg|
        org_card_ids += corg.card_templates.map { |ct| ct.id }
      end

      tab1_csv = CSV.generate(headers: true) do |csv|
        csv << attributes

        all_print_jobs = PrintJob.where("created_at >= '2016-04-01 00:00:00'",).where("created_at <= '2016-04-30 23:59:59'").where(is_sample: false).where(status_cd: 3).where(type_cd: 0).where('card_template_id in (?)',org_card_ids).order(created_at: :desc)
        all_print_jobs.each do |pj|
          pj.list_users.first.user_datum.each do |ud|
            printed_card = [pj.created_at.strftime("%m/%d/%Y %H:%M"), org.id, org.name]
            card_attributes.count.times do |i|
              next if i.eql?0
              printed_card << ud.data["DATA_#{i}"]
            end
            csv << printed_card
          end
        end
      end
    end
    
    send_data tab1_csv,
      :type => 'text/csv; charset=UTF-8;',
      :disposition => "attachment; filename=tab1-#{org.name.gsub(' ', '_')}.csv"
  end
  
  member_action :report_tab2, method: :get do
    org = resource
    attributes = ['Date','Company Name','Number','Card Cost','Shipping Cost']
    
    org_card_ids = org.card_templates.map { |ct| ct.id }
    org.child_organizations.each do |corg|
      org_card_ids += corg.card_templates.map { |ct| ct.id }
    end

    tab2_csv = CSV.generate(headers: true) do |csv|
      csv << attributes

      all_print_jobs = PrintJob.where("created_at >= '2016-04-01 00:00:00'",).where("created_at <= '2016-04-30 23:59:59'").where(is_sample: false).where(status_cd: 3).where(type_cd: 0).where('card_template_id in (?)',org_card_ids).order(created_at: :desc)
      all_print_jobs.each do |pj|
        printed_job = [pj.id, pj.created_at.strftime("%m/%d/%Y %H:%M"), org.name, pj.total_cards]
        card_cost = 0
        shipping_cost = 0
        if pj.financial_transaction.present?
          printed_job += [pj.financial_transaction.id]
          pj.financial_transaction.transaction_items.each do |ti|
            if ti.cost.costable_type.eql?'ShippingProvider'
              shipping_cost += ti.value
            else
              card_cost += ti.value
            end
          end
        end
        printed_job += ["$#{card_cost}", "$#{shipping_cost}"]
        csv << printed_job
      end
      
    end

    send_data tab2_csv,
      :type => 'text/csv; charset=UTF-8;',
      :disposition => "attachment; filename=tab2-#{org.name.gsub(' ', '_')}.csv"
  end

  member_action :report_tab3, method: :get do
    org = resource
    attributes = ['Company ID','Company Name','Number','Total']

    org_ids = [org.id]
    org_ids += org.child_organizations.map {|corg| corg.id}

    tab3_csv = CSV.generate(headers: true) do |csv|
      csv << attributes

      count = org.financial_transactions.where("created_at >= '2016-04-01 00:00:00'",).where("created_at <= '2016-04-30 23:59:59'").where(financial_transaction_sub_type: 4).count
      total = org.financial_transactions.where("created_at >= '2016-04-01 00:00:00'",).where("created_at <= '2016-04-30 23:59:59'").where(financial_transaction_sub_type: 4).sum(:debit)
      csv << [org.id, org.name, count, total]
      
      org.child_organizations.order(id: :asc).each do |corg|
        count = corg.financial_transactions.where("created_at >= '2016-04-01 00:00:00'",).where("created_at <= '2016-04-30 23:59:59'").where(financial_transaction_sub_type: 4).count
        total = corg.financial_transactions.where("created_at >= '2016-04-01 00:00:00'",).where("created_at <= '2016-04-30 23:59:59'").where(financial_transaction_sub_type: 4).sum(:debit)
        csv << [corg.id, corg.name, count, total]
      end
    end
    
    send_data tab3_csv,
      :type => 'text/csv; charset=UTF-8;',
      :disposition => "attachment; filename=tab3-#{org.name.gsub(' ', '_')}.csv"
  end

  collection_action :setup_organization, method: [:get, :post] do
    @organization = Organization.new

    if request.post?
      new_organization = Organization.new(permitted_params[:organization])
      new_organization.users.last.password = [*('a'..'z')].sample(8).join

      if new_organization.save
        address = new_organization.addresses.last
        address.organization_name = new_organization.name
        address.contact_id = new_organization.contacts.last.id
        address.save

        redirect_to admin_organization_path(new_organization), notice: 'Organization was successfully created.'
      end

      @organization = new_organization
    end
  end

  index do
    selectable_column
    id_column
    column :parent_organization
    column :name
    column :status, :sortable => :last_financial_transaction do |o|
      case o.status
      when :Initiated 
        status_tag( 'Initiated', :yellow )
      when :Pending
        status_tag( 'Pending', :yellow )
      when :Active
        status_tag( 'Active', :ok )
      when :Dorment
        status_tag( 'Dorment', :yellow )
      when :Inactive
        status_tag( 'Inactive', :red )
      else
        ""
      end
    end
    column :industry
    column :category
    # NewSystem is the default now
    # [HR] Delete if not used after 06/10/2017
    # column :system, :sortable => :system_cd do |o|
    #   case o.system
    #   when :Legacy
    #     status_tag( 'Legacy', :red )
    #   when :NewSystem
    #     status_tag( 'New System', :ok )
    #   else
    #     status_tag( 'Not Provided', :yellow )
    #   end
    # end
    column :balance, :class => "amount" do |o|
      number_to_currency(o.balance, negative_format: "(%u%n)")
    end
    if params[:q] && params[:q][:contacts_full_name_cont]
      column :contact_full_name, :class => "column_hightlight_warning" do |o|
        o.contacts.where('full_name ILIKE :full_name', full_name: '%' + params[:q][:contacts_full_name_cont] + '%').first.full_name
      end
    end
    if params[:q] && params[:q][:contacts_email_cont]
      column :contact_email, :class => "column_hightlight_warning" do |o|
        o.contacts.where('email ILIKE :email', email: '%' + params[:q][:contacts_email_cont] + '%').first.email
      end
    end
    if params[:q] && params[:q][:contacts_phone_number_cont]
      column :contact_phone_number, :class => "column_hightlight_warning" do |o|
        o.contacts.where('phone_number ILIKE :phone_number', phone_number: '%' + params[:q][:contacts_phone_number_cont] + '%').first.phone_number
      end
    end
    # NewSystem is the default now
    # [HR] Delete if not used after 06/10/2017
    # column :migration_status, :sortable => :migration_status_cd do |o|
    #   case o.migration_status
    #   when :migration_ok
    #     status_tag( 'Ok', :ok )
    #   when :migration_warning
    #     status_tag( 'Warning', :yellow )
    #   when :migration_error
    #     status_tag( 'Error', :red )
    #   when :cleared
    #     status_tag('Cleared')
    #   else
    #     ""
    #   end
    # end

    column :last_financial_transaction do |o|
      time_ago_in_words(o.last_financial_transaction) if o.last_financial_transaction.present?
    end
    column :financial_transaction do |o|
      link_to "Financial Transactions", admin_financial_transactions_path()+"?q%5Borganization_id_eq%5D=#{o.id}"
    end
    column :updated_at
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      f.input :name
      f.input :parent_organization
      # NewSystem is the default now
      # [HR] Delete if not used after 06/10/2017
      # unless f.object.new_record?
      #   f.input :legacy_id
      # end
      f.input :industry
      f.input :category
      f.input :overdraft, :as => :string
      f.input :hide_balance, :label => 'Hide Balance', :as => :check_boxes, :collection => [['', 1, {:checked => f.object.settings['hide_balance']}]]
      # NewSystem is the default now
      # [HR] Delete if not used after 06/10/2017
      # unless f.object.new_record?
      #   f.input :migration_status_cd, :label => 'Migration Status', :as => :select, :collection => Organization.migration_statuses.hash
      # end
    end
    actions
  end

  show do |v|
    attributes_table do
      row :id
      row :name
      row :parent_organization
      row :legacy_id
      row (:status) do |o|
        case o.status
        when :Initiated 
          status_tag( 'Initiated', :yellow )
        when :Pending
          status_tag( 'Pending', :yellow )
        when :Active
          status_tag( 'Active', :ok )
        when :Dorment
          status_tag( 'Dorment', :yellow )
        when :Inactive
          status_tag( 'Inactive', :red )
        else
          ""
        end
      end
      row :industry
      row :category
      # NewSystem is the default now
      # [HR] Delete if not used after 06/10/2017
      # row (:system) do |o|
      #   case o.system
      #   when :Legacy
      #     status_tag( 'Legacy', :red )
      #   when :NewSystem
      #     status_tag( 'New System', :ok )
      #   else
      #     status_tag( 'Not Provided', :yellow )
      #   end
      # end
      row (:balance) { |org| number_to_currency(org.balance, negative_format: "(%u%n)") }
      row (:overdraft) { |org| number_to_currency(org.overdraft, negative_format: "(%u%n)") }
      # row (:legacy_balance) { |org| number_to_currency(org.legacy_balance, negative_format: "(%u%n)") }
      row :total_jobs
      row :last_financial_transaction
      # NewSystem is the default now
      # [HR] Delete if not used after 06/10/2017
      # row (:migration_status) do |o|
      #   case o.migration_status
      #   when :migration_ok
      #     status_tag( 'Ok', :ok )
      #   when :migration_warning
      #     status_tag( 'Warning', :yellow )
      #   when :migration_error
      #     status_tag( 'Error', :red )
      #   when :cleared
      #     status_tag('Cleared')
      #   else
      #     ""
      #   end
      # end
      row :approved_card_template_count
      row :created_at
      row :updated_at
    end

    panel "Contacts" do
      table_for v.contacts do |c|
        column :full_name
        column :email
        column :phone_number
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_organization_contact_path(o.organization, o), :class => "member_link") +
          link_to('Edit', edit_admin_organization_contact_path(o.organization, o), :class => "member_link")
        end
      end
    end

    panel "Addresses" do
      table_for v.addresses do |c|
        column :label
        column :organization_name
        column :address1
        column :address2
        column :city
        column :state
        column :country
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_organization_address_path(o.organization, o), :class => "member_link") +
          link_to('Edit', edit_admin_organization_address_path(o.organization, o), :class => "member_link")
        end
      end
    end
    
    panel "Child Organizations" do
      table_for v.child_organizations do |c|
        column :id
        column :name
        # NewSystem is the default now
        # [HR] Delete if not used after 06/10/2017
        # column :system, :sortable => :system_cd do |o|
        #   case o.system
        #   when :Legacy
        #     status_tag( 'Legacy', :red )
        #   when :NewSystem
        #     status_tag( 'New System', :ok )
        #   else
        #     status_tag( 'Not Provided', :yellow )
        #   end
        # end
        column :last_financial_transaction do |o|
          time_ago_in_words(o.last_financial_transaction) if o.last_financial_transaction.present?
        end
        column (:balance) { |org| number_to_currency(org.balance, negative_format: "(%u%n)") }
        column 'Actions' do |o|
          link_to('Show', admin_organization_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_organization_path(o), :class => "member_link")
        end
      end
    end
    
    panel "Card Templates" do
      table_for v.card_templates do |ct|
        column :id
        column :name
        column :status do |o|
          case o.status
          when :Draft
            status_tag( 'Draft', :yellow )
          when :Approved
            status_tag( 'Approved', :ok )
          when :Cloned
            status_tag( 'Cloned', :red )
          else
            ""
          end
        end
        column :updated_at
        column 'Actions' do |o|
          link_to('Preview', preview_admin_card_template_path(o), :class => "member_link") +
          link_to('Show', admin_card_template_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_card_template_path(o), :class => "member_link")
        end
      end
    end
    
    panel "Shared Templates" do
      table_for v.shared_templates do |ec|
        column (:id) do |o|
          o.card_template.id
        end
        column (:name) do |o|
          o.card_template.name
        end
        column (:status) do |o|
          case o.card_template.status
          when :Draft
            status_tag( 'Draft', :yellow )
          when :Approved
            status_tag( 'Approved', :ok )
          when :Cloned
            status_tag( 'Cloned', :red )
          else
            ""
          end
        end
        column (:updated_at) do |o|
          o.card_template.updated_at
        end
        column 'Actions' do |o|
          link_to('Preview', preview_admin_card_template_path(o.card_template), :class => "member_link") +
          link_to('Show', admin_card_template_path(o.card_template), :class => "member_link") +
          link_to('Edit', edit_admin_card_template_path(o.card_template), :class => "member_link")
        end
      end
    end
    
    panel "Costs" do
      table_for v.costs do |c|
        column :quantity
        column (:value) { |cost| number_to_currency(cost.value, negative_format: "(%u%n)")}
        column :costable_item_label
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_cost_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_cost_path(o), :class => "member_link") +
          link_to('Delete', admin_cost_path(o), method: :delete, 
            data: { confirm: 'Are you certain you want to delete this?' }, :class => "member_link")
        end
      end
    end

    panel "Users" do
      table_for v.users do |c|
        column :email
        column (:role) { |u| u.roles.first.name }
        column :pin
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_user_path(o), :class => "member_link")
        end
      end
    end
    
    panel "Fonts" do
      # TODO (HR): implement will_paginate
      # https://github.com/activeadmin/activeadmin/issues/1116
      # https://github.com/activeadmin/activeadmin/blob/d9582f33f3c76bac04373f21c25b4efd2be90e65/docs/0-installation.md#will_paginate
      table_for v.fonts do |f|
        column :name
        column :global
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_font_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_font_path(o), :class => "member_link")
        end
      end
    end

    panel "Card Types" do
      table_for v.card_types do |f|
        column :name
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_card_type_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_card_type_path(o), :class => "member_link")
        end
      end
    end

    active_admin_comments
  end
  
  sidebar "Other information", only: [:show, :edit] do
    ul do
      li link_to "Card Templates", admin_card_templates_path()+"?q%5Borganization_id_eq%5D=#{organization.id}"
      li link_to "Cards", admin_organization_cards_path(organization)
      li link_to "Contacts", admin_organization_contacts_path(organization)
      li link_to "Addresses", admin_organization_addresses_path(organization)
      li link_to "Financial Transactions", admin_financial_transactions_path()+"?q%5Borganization_id_eq%5D=#{organization.id}"
      li link_to "Label Templates", admin_label_templates_path()+"?q%5Borganization_id_eq%5D=#{organization.id}"
      li link_to "Letter Templates", admin_letter_templates_path()+"?q%5Borganization_id_eq%5D=#{organization.id}"
      li link_to "Migration Logs", admin_migration_logs_path()+"?q%5Borganization_id_eq%5D=#{organization.id}"
      li link_to "Users", admin_users_path()+"?q%5Borganization_id_eq%5D=#{organization.id}"
    end
  end
  
  sidebar "Custom Actions", only: [:show] do
    ul do
      li link_to "Print Label", print_label_admin_organization_path(resource), :class => "member_link", method: :put
      # li link_to "Check Legacy Balance", check_legacy_balance_admin_organization_path(resource), :class => "member_link", method: :put
      li link_to "Tab 1 report", report_tab1_admin_organization_path(resource), :class => "member_link", method: :get
      li link_to "Tab 2 report", report_tab2_admin_organization_path(resource), :class => "member_link", method: :get
      li link_to "Tab 3 report", report_tab3_admin_organization_path(resource), :class => "member_link", method: :get
    end
  end
  
  filter :id_gteq, as: :string, label: 'From Organization ID'
  filter :id_lteq, as: :string, label: 'To Organization ID'
  filter :name
  filter :industry
  filter :category
  # NewSystem is the default now
  # [HR] Delete if not used after 06/10/2017
  # filter :system_cd, as: :select, collection: Organization.systems.hash, label: 'System'
  # TODO (HR): status_cd is not being used anymore and should be cleaned on version 2.0
  # filter :status_cd, as: :select, collection: Organization.statuses.hash, label: 'Status'
  # NewSystem is the default now
  # [HR] Delete if not used after 06/10/2017
  # filter :migration_status_cd, as: :select, collection: Organization.migration_statuses.hash, label: 'Migration Status'
  filter :last_financial_transaction

  filter :contacts_full_name_cont, as: :string, label: 'Contact Full Name'
  filter :contacts_email_cont, as: :string, label: 'Contact Email'
  filter :contacts_phone_number_cont, as: :string, label: 'Contact Phone Number'

  filter :created_at
  filter :updated_at
  
  controller do
    def scoped_collection
      super.includes :parent_organization, :industry, :category
    end

    def create
      params[:organization][:settings] = {hide_balance: params[:organization][:hide_balance].length > 1}
      super
    end

    def update
      resource.settings.merge!({hide_balance: params[:organization][:hide_balance].length > 1})
      super
    end
  end
end
