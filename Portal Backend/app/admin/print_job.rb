ActiveAdmin.register PrintJob do
  permit_params :address, :card_template, :status_cd, :shipping_provider_id, :workstation_id
  menu priority: 1

  config.per_page = 100

  scope "Before 4PM", :print_job_is_today
  scope "Print label", :print_job_label 
  scope "Scheduled", :print_job_scheduled
  scope "Finished", :print_job_finished
  scope "All", :print_job_all

  actions :all, :except => [:new]

  batch_action :batch_print do |ids|
    error_jobs = []
    success_jobs = []
    PrintJob.find(ids).each do |pj|
      if pj.workstation_id.present?
        pj.In_Progress!
        pj.save!
        Jobs::PrintCardJob.enqueue({print_job_id: pj.id}, pj.workstation.workers_queue)
        success_jobs << "ID:#{pj.id} - Org:#{pj.organization.name}"
      else
        error_jobs << "ID:#{pj.id} - Org:#{pj.organization.name}"
      end
    end
    flash[:notice] = "Print #{'Job'.pluralize(success_jobs.count)} (#{success_jobs.join(', ')}) sent for production!" unless success_jobs.empty?
    flash[:error] = "Print #{'Job'.pluralize(error_jobs.count)} (#{error_jobs.join(', ')}) needs to be associated with a workstation!" unless error_jobs.empty?
    redirect_to :back
  end

  batch_action :assign_workstation, form: {
      # workstation: Workstation.all.map { |i| [i.name, i.id] }
  } do |ids, inputs|
      print_jobs = PrintJob.where(id: ids)

      if print_jobs.collect { |print_job| print_job.organization_id }.uniq.length > 1
        redirect_to :back, alert: "Selected Print Jobs should be assigned to the same organization"
      end

      if print_jobs.collect { |print_job| print_job.card_template.card_type_id }.uniq.length > 1
        redirect_to :back, alert: "Selected Print Jobs should have the same card type."
      end

      print_jobs.update_all({workstation_id: inputs[:workstation]})

      msgs = []
      print_jobs.each do |print_job|
        if print_job.workstation_warning? && print_job.Scheduled?
          msgs << "Put #{print_job.total_cards} #{"card".pluralize(print_job.total_cards)} of type <span class='badge'>#{print_job.card_type.name}</span> on <span class='badge alert-warning'>#{print_job.workstation.name}</span>"
        end
      end

      session[:batch_assign_workstation_msg] = msgs
      redirect_to :back
  end
  
  member_action :print, method: :put do
    unless resource.workstation.present?
      flash[:error] = "Print Job (ID: #{resource.id}) needs to be associated with a workstation!"
      redirect_to :back
      return
    end
    resource.In_Progress!
    resource.save!
    Jobs::PrintCardJob.enqueue({print_job_id: resource.id}, resource.workstation.workers_queue)
    redirect_to :back, notice: "Print Job (ID: #{resource.id}) sent to the Print Workers Queue!"
  end
  
  member_action :print_label, method: :put do
    Jobs::PrintLabelJob.enqueue({print_job_id: resource.id}, resource.workstation.workers_queue)
    redirect_to :back, notice: "Label sent to the Print Workers Queue!"
  end
  
  member_action :reprint, method: :get do
    @print_job = resource
  end
  
  member_action :submit, method: :post do
    if !params["reprint"].present? or !params["reprint"]["ids"].present?
      flash[:error] = "To reprint a job you have to select at least one card."
      redirect_to reprint_admin_print_job_path(resource)
      return
    end
    
    new_print_job = PrintJob.from_reprint_params(resource, params["reprint"].permit!)
    new_print_job.charge_organization if new_print_job.charge?

    redirect_to admin_print_job_path, notice: "Print Job scheduled successfully."
  end
  
  member_action :update_no_redir, method: :put do
    print_job = resource
    print_job.update(permitted_params["print_job"])
    msgs = []
    
    if print_job.workstation_warning? && print_job.Scheduled?
      # Requires to change the card type in the Workstation
      msgs << "Put #{print_job.total_cards} #{"card".pluralize(print_job.total_cards)} of type <span class='badge'>#{print_job.card_type.name}</span> on <span class='badge alert-warning'>#{@print_job.workstation.name}</span>"
    end
    
    if !print_job.is_sample? and print_job.organization.is_first_print_job?
      # First print job of a new or migrated customer 
      if @print_job.organization.is_legacy?
        msgs << "Organization <span class='badge alert-success'>#{@print_job.organization.name}</span> has been migrated from the legacy system!"
      else
        msgs << "<span class='badge alert-success'>#{@print_job.organization.name}</span> is a brand new customer!"
      end
    end
    
    render json: {status: 'OK', messages: msgs}
  end
  
  action_item :print, only: :show do
    link_to("Print", print_admin_print_job_path(print_job), :class => "member_link", method: :put) if (print_job.Scheduled? and print_job.workstation.present?)
  end

  action_item :print_label, only: :show do
    link_to("Print Label", print_label_admin_print_job_path(print_job), :class => "member_link", method: :put)
  end
  
  action_item :reprint, only: :show do
    link_to("Reprint", reprint_admin_print_job_path(print_job), :class => "member_link")  if (print_job.workstation.present? and !print_job.Scheduled? and !print_job.Label?)
  end
  
  controller do
    def index
      if !params["scope"].present?
        params["scope"] = "before_4pm"
      end
      
      if (params["scope"].eql?"finished") && (params["order"].nil?)
        params["order"] = "printed_at_desc"
      end
      
      @total_jobs, @jobs_per_shipping, @companies = PrintJob.summary

      if session[:batch_assign_workstation_msg].present?
        @batch_assign_workstation_msg = session[:batch_assign_workstation_msg]
        session.delete(:batch_assign_workstation_msg)
      end

      super
    end
    
    def scoped_collection
      super.includes :organization, :card_type, :shipping_provider, :card_template, :workstation
    end
  end

  index do |p|
    render partial: "alert_modal"
    
    panel "Print Job Summary", :id => "summary-panel" do
      render partial: "summary"
    end
    selectable_column
    id_column
    column :type, sortable: :type_cd
    column :organization, sortable: 'organizations.name'
    column :status
    column :card_type, sortable: 'card_types.name'
    column :total_cards
    column :shipping_provider, sortable: 'shipping_providers.name' do |o|
      shipping_name = (o.shipping_provider.present? ? o.shipping_provider.name : "")
      shipping_symbol = ((shipping_name.eql?'USPS') ? :ok : :red)
      html = ''
      html = status_tag(shipping_name, shipping_symbol) if shipping_name.present?
      address_name = (o.address_type.eql? :print_job_address_on_file) ? 'On File' : 'Drop Ship'
      address_symbol = ((address_name.eql?'On File') ? :blue : :yellow)
      html += status_tag(address_name, address_symbol)
      html += status_tag('NEW', :gray) if !o.is_sample? and o.organization.is_first_print_job?
      address_alert = o.delivery_address_alert
      html += status_tag(address_alert.first, address_alert.second) unless address_alert.first.empty?
      
      html
    end
    # column :special_handlings_tokens
    column :special_handlings
    column :updated_at
    column :printed_at
    
    column :data_1_card if params["q"].present? and params["q"]["organization_name_cont"].present?
    
    # column :workstation
    column 'Workstation', :sortable => :workstation_id do |resource|
      if resource.Scheduled?
        column_select(resource, :workstation_id, [""] + Workstation.all.map { |i| [i.id, i.name] })
      elsif resource.workstation.present?
        resource.workstation.name
      end
    end
    column 'Ready for Printing' do |c|
      if c.Scheduled? and c.workstation.present?
        link_to("Print", print_admin_print_job_path(c), :class => "member_link", method: :put) +
        link_to("Print Label", print_label_admin_print_job_path(c), :class => "member_link", method: :put)
      elsif c.Scheduled?
        link_to("Print", print_admin_print_job_path(c), :class => "member_link", method: :put)
      elsif (c.Finished? or c.Failed? or c.No_Balance?)
        link_to("Reprint", reprint_admin_print_job_path(c), :class => "member_link") +
        link_to("Print Label", print_label_admin_print_job_path(c), :class => "member_link", method: :put)
      end
    end
    
    column '' do |c|
      link_to("View", admin_print_job_path(c), :class => "member_link") +
      link_to("Edit", edit_admin_print_job_path(c), :class => "member_link") +
      link_to("Delete", admin_print_job_path(c), method: :delete, 
        data: { confirm: 'Are you certain you want to delete this?' }, :class => "member_link")
    end
  end
  
  show do |p|
    render partial: "notice", locals: {print_job: p}

    attributes_table do
      row :id
      row :type
      row :workstation
      row :organization
      row :card_template
      row :total_cards
      row :shipping_provider
      row :financial_transaction
      row :address
      row :status
      row :status_message
      row :printed_at
      row :created_at
      row :updated_at
    end
    
    panel "Special Handling" do
      table_for p.card_template.extended_special_handlings do |esh|
        column :name
        column :token
        column :description
      end
    end
    
    panel "Cards / Users" do
      table_for p.list_users.first.user_datum do |ua|
        column :id
        column :status
        column (:Attribute_1) { |t| t.data["DATA_1"] }
        column (:Attribute_2) { |t| t.data["DATA_2"] }
        column (:Attribute_3) { |t| t.data["DATA_3"] }
        column (:preview_link) { |t| link_to('Front', image_card_template_path(p.card_template.id, t.id, 'front'), {target: 'blank'}) + ' - ' + link_to('Back', image_card_template_path(p.card_template.id, t.id, 'back'), {target: 'blank'})}
      end if p.total_cards > 0
    end

    active_admin_comments
  end
  
  form do |f|
    f.semantic_errors *f.object.errors.keys
    panel 'Print Job Details' do
      render partial: "details", locals: {print_job: print_job}
    end unless f.object.new_record?

    panel "Special Handling" do
      table_for print_job.card_template.extended_special_handlings do |esh|
        column :name
        column :description
      end
    end unless f.object.new_record?

    inputs do
      if f.object.status_cd == 1
        input :status_cd, label: 'Status', as: :select, :collection => {Scheduled: 1, Duplicated: 6, Not_Printed: 7}, :include_blank => false
      end
      input :workstation
    end
    actions
  end

  filter :id
  filter :organization_id_eq, as: :string, label: 'Organization ID'
  filter :organization_name_cont, as: :string, label: 'Organization Name'
  # filter :organization
  filter :type_cd, as: :select, collection: proc { PrintJob.types.hash }, label: 'Type'
  filter :workstation
  filter :card_template_name_cont, as: :string, label: 'Card Template Name'
  # filter :card_template
  filter :status_cd, as: :select, collection: proc { PrintJob.statuses.hash }, label: 'Status'
  filter :shipping_provider
  filter :special_handlings
  filter :created_at
  filter :updated_at

end
