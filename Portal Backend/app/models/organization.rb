class Organization < ActiveRecord::Base
  has_many :users, :dependent => :destroy
  has_many :card_templates, :dependent => :destroy
  has_many :costs, :dependent => :destroy
  has_many :addresses, :dependent => :destroy
  has_many :contacts, :dependent => :destroy
  has_many :financial_transactions, :dependent => :destroy
  has_many :label_templates, :dependent => :destroy
  has_many :letter_templates, :dependent => :destroy
  has_and_belongs_to_many :fonts, :dependent => :destroy
  has_many :special_handlings, :dependent => :destroy
  has_many :migration_logs, :dependent => :destroy
  belongs_to :parent_organization, class_name: 'Organization'
  belongs_to :industry
  belongs_to :category
  has_many :shared_templates, :dependent => :destroy
  has_many :children_organizations, class_name: "Organization", foreign_key: "parent_organization_id"
  has_and_belongs_to_many :card_types, :join_table => :organizations_card_types
  has_many :cards, :dependent => :destroy
  has_many :print_jobs

  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :contacts
  accepts_nested_attributes_for :users

  has_paper_trail
  monetize :balance
  
  as_enum :system, Legacy: 0, NewSystem: 1
  as_enum :status, Active: 0, Inactive: 1, NoTransaction: 2
  as_enum :migration_status, migration_ok: 0, migration_warning: 1, migration_error: 2, migration_undefined: 3, cleared: 4

  # Balance can be smaller than overdraft
  # validate :balance_bigger_than_overdraft

  validates :name, presence: true
  
  default_scope { order(name: :asc) }

  scope :org_is_pending, -> { where("last_financial_transaction is ?", nil) }
  scope :org_is_active, ->(time = 6.months) { where("last_financial_transaction >= ?", Time.now - time) }
  scope :org_is_dorment, ->(time_start = 6.months, time_end = 18.months) { where("last_financial_transaction > ? and last_financial_transaction <= ?", Time.now - time_end, Time.now - time_start) }
  scope :org_is_inactive, ->(time = 18.months) { where("last_financial_transaction < ?", Time.now - time) }
  
  def parent_id
    # it may not have a parent
    parent_organization.try(:id)
  end

  def has_parent?
    parent_organization.present?
  end

  def has_children?
    children_organizations.exists?
  end
  
  def status
    return :Pending unless self.last_financial_transaction.present?
    last_ft = self.last_financial_transaction
    t_now = Time.now
    return :Active if (t_now - 6.months) < last_ft
    return :Dorment if (t_now - 18.months ) < last_ft
    return :Inactive
  end
  
  def address(label)
    addr = self.addresses.where(:primary => true).first
    addr ||= self.addresses.where("lower(label) = ?", label).first
    addr ||= self.addresses.first
    
    addr
  end
  
  def delivery_address(label = "primary")
    addr = self.address(label)
    
    addr.present? ? addr.to_print : ["",""]
  end
  
  def pay_for_job(print_job)
    print_job_total_users = print_job.list_users.first.total_users
    status, job_total_cost, card_cost, card_total_cost, shipping_cost, shipping_total_cost, card_option_cost, message = self.has_balance_for_job(print_job, print_job_total_users)
    
    new_t = self.financial_transactions.new
    new_t.debit = job_total_cost
    new_t.description = "Print Job ID #{print_job.id}"
    # TODO (HR): will continue using operation_cd until the new financial transaction sub type feature is mature
    new_t.Debit!
    # Item 4 should always be the Print Job debit sub type
    new_t.financial_transaction_sub_type = FinancialTransactionSubType.find(4)
    new_t.print_job_id = print_job.id
    new_t.save!
    
    card_ti = new_t.transaction_items.new
    card_ti.cost = card_cost
    card_ti.total = print_job_total_users
    card_ti.value = card_total_cost
    card_ti.save!
    
    shipping_ti = new_t.transaction_items.new
    shipping_ti.cost = shipping_cost
    shipping_ti.total = 1
    shipping_ti.value = shipping_total_cost
    shipping_ti.save!
    
    # iterate through card_option_cost and create separate transaction_items
    card_option_cost.each do |card_option_cost_item|
      co_ti = new_t.transaction_items.new
      co_ti.cost = card_option_cost_item[1]
      co_ti.total = print_job_total_users
      co_ti.value = print_job_total_users * co_ti.cost.value
      co_ti.save!
    end
    
    [true, message]
  end
  
  def child_organizations
    Organization.where(parent_organization_id: self.id)
  end
  
  def give_me_a_card_template
    ct = self.card_templates.first
    unless ct.present?
      sct = self.shared_templates.first
      ct = sct.card_template if sct.present?
    end
    
    ct
  end
  
  def self.organizations_tree(resource, removeParent = true)
      returnvar = Array.new
      parent = self.getParent(resource.organization)
      returnvar = self.organizations_childs_recursion(parent)
      returnvar << parent

      if removeParent
          returnvar.delete(resource.organization)
      end

      return returnvar
  end
  
  def self.getParent(resource)
    while(resource.has_parent?)
      resource = resource.parent_organization
    end
    return resource
  end
  
  def self.organizations_childs_recursion(resource, returnvar=nil)
    if returnvar.nil? 
      returnvar = Array.new
    end
    if(resource.has_children?)
      resource.children_organizations.each do |child|
        returnvar << child
        if(child.has_children?)
          self.organizations_childs_recursion(child,returnvar)
        end
      end
    end
    return returnvar
  end

  def total_cards
    self.cards.count
  end

  def total_card_templates
    card_templates_count = self.card_templates.where(status_cd: 1).count
    if self.shared_templates.present?
      self.shared_templates.each do |shared_template|
        card_template = shared_template.clone_card_template.present? ? shared_template.clone_card_template : shared_template.card_template
        if card_template.status
          card_templates_count += card_templates_count
        end
      end
    end
    card_templates_count
  end

  def hide_balance?
    if self.settings["hide_balance"]
      return true
    elsif self.has_parent?
      return self.parent_organization.hide_balance?
    end
    false
  end
  
  def who_pays_for_my_jobs
    self.parent_organization_id.present? ? self.parent_organization.who_pays_for_my_jobs : self
  end
  
  def has_balance_for_job(print_job, total_users)
    # This function returns the following: status, job_total_cost, card_cost, card_total_cost, shipping_cost, shipping_total_cost, card_option_cost array
    return [true, 0, nil, 0, nil, 0, [], ""] unless print_job.charge

    card_cost = Cost.find_cost(self, print_job.card_template.card_type, total_users)
    shipping_cost = nil
    shipping_cost = Cost.find_cost(self, print_job.shipping_provider, total_users) if print_job.shipping_provider.present?

    card_total_cost = card_cost.value * total_users
    shipping_total_cost = shipping_cost.present? ? shipping_cost.value : 0
    
    card_option_cost = []
    card_option_total_cost = 0
    print_job.card_template.options.each do |option|
      next if (option["key"].eql?"slot_punch" and option["value"].eql?"none")
      next if (option["key"].eql?"overlay" and option["value"].eql?"false")
      
      card_option = CardOption.where(:element => "options").where(:key => option["key"]).where("value in (?)", ["", option["value"]]).first
      next unless card_option.present?

      card_option_cost_item = Cost.find_cost(self, card_option, total_users)
      next unless card_option_cost_item.present?
      
      card_option_total_cost += card_option_cost_item.value * total_users
      card_option_cost << [card_option, card_option_cost_item]
    end
    
    print_job.card_template.card_data.each do |card_data|
      card_option = CardOption.where(:element => "card_data").where(:key => card_data["type"]).first
      next unless card_option.present?

      card_option_cost_item = Cost.find_cost(self, card_option, total_users)
      next unless card_option_cost_item.present?
      
      card_option_total_cost += card_option_cost_item.value * total_users
      card_option_cost << [card_option, card_option_cost_item]
    end
    
    print_job.card_template.special_handlings.each do |sh|
      sh_cost_item = Cost.find_cost(self, sh, total_users)
      next unless sh_cost_item.present?
      
      card_option_total_cost += sh_cost_item.value * total_users
      card_option_cost << [sh, sh_cost_item]
    end
    
    job_total_cost = card_total_cost + shipping_total_cost + card_option_total_cost
    
    Rails.logger.debug("This job will cost #{job_total_cost}")

    has_balance = true
    message = ""
    organization_to_be_charged = print_job.organization.who_pays_for_my_jobs
    if organization_to_be_charged.balance + organization_to_be_charged.overdraft < job_total_cost
      has_balance = false
      message = "Balance (Org ID/NAME: #{organization_to_be_charged.id}/#{organization_to_be_charged.name}) is #{organization_to_be_charged.balance}, with overdraft of #{organization_to_be_charged.overdraft} and the job total cost is #{job_total_cost}."
      Rails.logger.error(message)
      begin
        MailUtils.send_simple_message("[EVEREST] Organization out of balance", message)
      rescue Exception => e
        Rails.logger.error("Exception message: #{e.message}")
      end
    end

    return [has_balance, job_total_cost, card_cost, card_total_cost, shipping_cost, shipping_total_cost, card_option_cost, message]
  end
  
  def letter_replaceable_attributes
    primary_address = self.addresses.where(primary: true).first
    {
      COMPNO: self.id,
      COMPNAME: self.name,
      COMPADD1: primary_address.address1,
      COMPADD2: primary_address.address2,
      COMPADD3: primary_address.city,
      COMPADD4: primary_address.state,
      COMPPOSTCODE: primary_address.zip_code,
      COMPPHONE: primary_address.contact.phone_number,
      COMPCONTACT: primary_address.contact.full_name,
      COMPEMAIL: primary_address.contact.email
    }
  end
  
  def is_first_print_job?
    (self.total_jobs.eql?0)
  end
  
  def is_legacy?
    (self.id < 20000000)
  end
  
  def check_legacy_balance
    org = self
    wsdl_user = self.users.first

    return_value = true
    return_msg = "This feature is deprecated"
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
    #         return_value = false
    #         return_msg = "Organization balance ($#{org.balance.to_s}) is different from legacy system ($#{legacy_balance})."
    #       else
    #         return_value = true
    #         return_msg = "Organization balance is the same as the legacy system!"
    #       end
    #     else
    #       return_value = false
    #       return_msg = "Unable to check balance for Organization #{org.name}. Possibly auth failed for user '#{wsdl_user.email}' with '#{wsdl_user.pin}'"
    #     end
    #   rescue Exception => e
    #     # 2nd check not ok
    #     return_value = false
    #     return_msg = "May the force be with you. And give Helio a slack call!"
    #     Rails.logger.info("Check balance exception: #{e.message}")
    #     Rails.logger.info(e.backtrace)
    #   end
    # else
    #   return_value = false
    #   return_msg = "Organization don't have a Admin user"
    # end

    [return_value, return_msg]
  end
  
  def build_report_xls(params = {})
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'Print Report'
    sheet1 = self.tab1_report(sheet1, params)
    
    sheet2 = book.create_worksheet :name => 'Details'
    sheet2 = self.tab2_report(sheet2, params)
    
    sheet3 = book.create_worksheet :name => 'Totals'
    sheet3 = self.tab3_report(sheet3, params)
    
    book
  end
  
  def tab1_report(sheet, params)
    attributes = ['Date','Company ID','Company Name', 'Card Template ID', 'Card Template Name']

    if params[:include_mailing_address] == '1'
      attributes += ['ADD1', 'ADD2', 'City', 'State', 'Zip']
    end

    org = self
    act = org.card_templates.first

    if act.present?
      # card_attributes = act.template_fields.map { |obj| obj['label'] }
      card_attributes = []
      51.times do |i|
        card_attributes << "Data #{i}" unless i.eql?0
      end
      
      attributes += card_attributes
      attributes.delete('Portrait')
      attributes.delete('Signature')
      org_card_ids = org.card_templates.map { |ct| ct.id }
      org.child_organizations.each do |corg|
        org_card_ids += corg.card_templates.map { |ct| ct.id }
      end

      sheet.row(0).replace attributes

      from_date = DateTime.parse(params[:from_date] + "T00:00:00" + Time.zone.now.strftime('%Z'))
      to_date = DateTime.parse(params[:to_date] + "T00:00:00" + Time.zone.now.strftime('%Z')) + 1.day
      
      all_print_jobs = PrintJob.where("created_at >= ?",from_date).where("created_at < ?", to_date).where(is_sample: false).where('status_cd in (?)', [2,3]).where(type_cd: 0).where('card_template_id in (?)',org_card_ids).order(created_at: :desc)
      row_counter = 1
      all_print_jobs.each do |pj|
        if params[:include_mailing_address] == '1'
          if pj.context["Add1"].present?
            pj_address = [
              pj.context["Add1"].present? ? pj.context["Add1"] : '',
              pj.context["Add2"].present? ? pj.context["Add2"] : '',
              pj.context["Add3"].present? ? pj.context["Add3"] : '',
              pj.context["Add4"].present? ? pj.context["Add4"] : '',
              pj.context["Postcode"].present? ? pj.context["Postcode"] : ''
            ]
          else
            addr = pj.organization.addresses.where(:primary => true).first
            addr ||= pj.organization.addresses.first

            if addr.present?
              pj_address = [
                addr.address1.present? ? addr.address1 : '',
                addr.address2.present? ? addr.address2 : '',
                addr.city.present? ? addr.city : '',
                addr.state.present? ? addr.state : '',
                addr.zip_code.present? ? addr.zip_code : ''
              ]
            else
              pj_address = ['', '', '', '', '']
            end
          end
        end

        pj.list_users.first.user_datum.each do |ud|
          ud_card = ud.card_template
          printed_card = [pj.created_at.strftime("%m/%d/%Y %H:%M"), pj.organization.id, pj.organization.name, ud_card.id, ud_card.name]

          if params[:include_mailing_address] == '1'
            printed_card += pj_address
          end

          card_attributes.count.times do |i|
            next if i.eql?0
            break if !ud.data["DATA_#{i}"].blank? && ud.data["DATA_#{i}"].match(/^DATA_\d+$/).present?
            printed_card << ud.data["DATA_#{i}"] unless ud.data["DATA_#{i}"].blank?
          end
          sheet.row(row_counter).replace printed_card
          row_counter += 1
        end
      end
    end

    sheet
  end
  
  def tab2_report(sheet, params)
    attributes = ['Print Job ID', 'Date','Company ID','Company Name','Number','Financial Transaction ID','Card Cost','Shipping Cost']
    org = self
    
    sheet.row(0).replace attributes

    org_card_ids = org.card_templates.map { |ct| ct.id }
    org.child_organizations.each do |corg|
      org_card_ids += corg.card_templates.map { |ct| ct.id }
    end

    from_date = DateTime.parse(params[:from_date] + "T00:00:00" + Time.zone.now.strftime('%Z'))
    to_date = DateTime.parse(params[:to_date] + "T00:00:00" + Time.zone.now.strftime('%Z')) + 1.day

    all_print_jobs = PrintJob.where("created_at >= ?",from_date).where("created_at < ?", to_date).where(is_sample: false).where('status_cd in (?)', [2,3]).where(type_cd: 0).where('card_template_id in (?)',org_card_ids).order(created_at: :desc)
    row_counter = 1
    all_print_jobs.each do |pj|
      printed_job = [pj.id, pj.created_at.strftime("%m/%d/%Y %H:%M"), pj.organization.id, pj.organization.name, pj.total_cards]
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
      sheet.row(row_counter).replace printed_job
      row_counter += 1
    end

    sheet
  end
  
  def tab3_report(sheet, params)
    attributes = ['Company ID','Company Name','Number of cards','Total']
    org = self

    sheet.row(0).replace attributes

    row_counter = 1
    
    from_date = DateTime.parse(params[:from_date] + "T00:00:00" + Time.zone.now.strftime('%Z'))
    to_date = DateTime.parse(params[:to_date] + "T00:00:00" + Time.zone.now.strftime('%Z')) + 1.day

    # count = org.financial_transactions.where("created_at >= ?",from_date).where("created_at < ?",to_date).where(financial_transaction_sub_type: 4).count
    count = PrintJob.where("created_at >= ?",from_date).where("created_at < ?", to_date).where(is_sample: false).where('status_cd in (?)', [2,3]).where(type_cd: 0).where(organization_id: org.id).sum(:total_cards)
    if count > 0
      total = org.financial_transactions.where("created_at >= ?",from_date).where("created_at < ?",to_date).where(financial_transaction_sub_type: 4).sum(:debit)
      sheet.row(1).replace [org.id, org.name, count, total]
      row_counter += 1
    end

    org.child_organizations.order(id: :asc).each do |corg|
      # count = corg.financial_transactions.where("created_at >= ?",from_date).where("created_at < ?",to_date).where(financial_transaction_sub_type: 4).count
      count = PrintJob.where("created_at >= ?",from_date).where("created_at < ?", to_date).where(is_sample: false).where('status_cd in (?)', [2,3]).where(type_cd: 0).where(organization_id: corg.id).sum(:total_cards)
      if count > 0
        total = corg.financial_transactions.where("created_at >= ?",from_date).where("created_at < ?",to_date).where(financial_transaction_sub_type: 4).sum(:debit)
        sheet.row(row_counter).replace [corg.id, corg.name, count, total]
        row_counter += 1
      end
    end
  end
  
  def self.review_organization_status
    Organization.find_each(batch_size: 5000) do |o|
      last_financial_transaction = o.financial_transactions.last
      next unless last_financial_transaction.present?
      if last_financial_transaction.created_at + 18.months < Time.now
        o.Inactive!
      else
        o.Active!
      end
      o.save!
    end
  end
  
  def self.switch_range(from_organization_id, to_organization_id)
    count = 0
    Organization.where('id >= ?', from_organization_id).where('id <= ?', to_organization_id).where(system_cd: 0).find_each(batch_size: 5000) do |org|
      unless org.check_legacy_balance.first
        output_message = "[ORG::SWITCH::RANGE] Org (ID:#{org.id}) '#{org.name}' balance doesn't reconcile."
        puts output_message
        Rails.logger.info(output_message)
        next
      end
      org.NewSystem!
      org.save!
      
      output_message = "[ORG::SWITCH::RANGE] Org (ID:#{org.id}) '#{org.name}' has been migrated as part of a range."
      puts output_message
      Rails.logger.info(output_message)
      count += 1
    end

    output_message = "[ORG::SWITCH::RANGE] Switched #{count} organizations "
    puts output_message
    Rails.logger.info(output_message)
  end

  def self.switch_no_templates(from_organization_id, to_organization_id)
    count = 0
    Organization.where('id >= ?', from_organization_id).where('id <= ?', to_organization_id).where(system_cd: 0).org_is_inactive.find_each(batch_size: 5000) do |org|
      next if org.parent_organization.present? or org.child_organizations.present?

      if (org.migration_ok? or org.migration_warning?) and !org.card_templates.present? # !org.card_templates.present?
        next unless org.check_legacy_balance.first
        org.NewSystem!
        org.save!
        
        output_message = "[ORG::SWITCH::NO_TEMPLATES] Org (ID:#{org.id}) '#{org.name}' has migration status OK and has no template."
        puts output_message
        Rails.logger.info(output_message)
        count += 1
      end
    end
    
    output_message = "[ORG::SWITCH::NO_TEMPLATES] Switched #{count} organizations "
    puts output_message
    Rails.logger.info(output_message)
  end

  def self.switch_inactive(from_organization_id, to_organization_id)
    count = 0
    Organization.where('id >= ?', from_organization_id).where('id <= ?', to_organization_id).where(system_cd: 0).org_is_inactive.find_each(batch_size: 5000) do |org|
      if org.parent_organization.present? or org.child_organizations.present?
        output_message = "[ORG::SWITCH::INACTIVE] Org (ID:#{org.id}) '#{org.name}' has parent or child organization."
        puts output_message
        Rails.logger.info(output_message)
        next
      end

      if org.migration_ok?
        unless org.check_legacy_balance.first
          output_message = "[ORG::SWITCH::INACTIVE] Org (ID:#{org.id}) '#{org.name}' balance doesn't reconcile."
          puts output_message
          Rails.logger.info(output_message)
          next
        end
        org.NewSystem!
        org.save!
        
        output_message = "[ORG::SWITCH::INACTIVE] Org (ID:#{org.id}) '#{org.name}' has migration status OK and is inactive."
        puts output_message
        Rails.logger.info(output_message)
        count += 1
      end
    end

    output_message = "[ORG::SWITCH::INACTIVE] Switched #{count} organizations "
    puts output_message
    Rails.logger.info(output_message)
  end

  def self.switch_migration_ok(from_organization_id, to_organization_id)
    count = 0
    Organization.where('id >= ?', from_organization_id).where('id <= ?', to_organization_id).where(system_cd: 0).find_each(batch_size: 5000) do |org|
      next if org.parent_organization.present? or org.child_organizations.present?
      
      if org.migration_ok?
        unless org.check_legacy_balance.first
          output_message = "[ORG::SWITCH::MIGRATION_OK] Org (ID:#{org.id}) '#{org.name}' balance doesn't reconcile."
          puts output_message
          Rails.logger.info(output_message)
          next
        end
        org.NewSystem!
        org.save!
        
        output_message = "[ORG::SWITCH::MIGRATION_OK] Org (ID:#{org.id}) '#{org.name}' has migration status OK."
        puts output_message
        Rails.logger.info(output_message)
        count += 1
      end
    end

    output_message = "[ORG::SWITCH::MIGRATION_OK] Switched #{count} organizations "
    puts output_message
    Rails.logger.info(output_message)
  end
  
  private
  
  # def balance_bigger_than_overdraft
  #   errors.add(:balance, "(of #{self.balance.to_money}) can't be smaller than overdraft (of #{self.overdraft.to_money})") if self.balance < self.overdraft*-1
  # end
  
end
