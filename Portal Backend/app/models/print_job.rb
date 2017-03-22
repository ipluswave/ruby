class PrintJob < ActiveRecord::Base
  belongs_to :card_template
  belongs_to :organization
  has_one :card_type, through: :card_template
  belongs_to :shipping_provider
  belongs_to :workstation
  has_one :site, through: :workstation
  has_many :list_users, :dependent => :destroy
  has_one :financial_transaction
  
  as_enum :status, Created: 0, Scheduled: 1, In_Progress: 2, Finished: 3, Failed: 4, No_Balance: 5, Duplicated: 6, Not_Printed: 7
  as_enum :type, Normal: 0, Reprint: 1, Letter: 2, Label: 3
  as_enum :api_version, WSDL: 0, JSON_V1: 1, JSON_V2: 2
  
  validates :card_template, presence: true

  scope :print_job_is_today, -> { where("print_jobs.status_cd = 1").where("print_jobs.created_at <= ?", Time.now.in_time_zone('Eastern Time (US & Canada)').change(hour: 16)) }
  scope :print_job_label, -> { where("print_jobs.status_cd = 1").where("print_jobs.type_cd = 3") }
  scope :print_job_scheduled, -> { where("print_jobs.status_cd = 1") }
  scope :print_job_finished, -> { where("print_jobs.status_cd in (3, 4)") }
  scope :print_job_all, -> { where("1 = 1") }
  
  def data_1_card
    begin
      self.list_users.first.user_datum.first.data["DATA_1"]
    rescue
      "Invalid - Error"
    end
  end
  
  def add_users(params, from_wsdl = false)
    lu = self.list_users.first_or_initialize
    lu.add_users(params, from_wsdl)
  end

  def add_cards(cards)
    lu = self.list_users.first_or_initialize
    lu.add_cards(cards)
  end
  
  def append_status_message(message)
    self.status_message << "\n" if self.status_message.length > 0
    self.status_message << message
  end
  
  def should_print_label?
    self.Normal? or self.Label?
  end
  
  def should_print_letter?
    (self.Normal? or self.Letter?)
  end
  
  def should_print_cards?
    (self.Normal? or self.Reprint?)
  end
  
  def has_balance_for_job(total_users)
    self.organization.has_balance_for_job(self, total_users).first
  end
  
  def charge_organization
    res, mes = self.organization.pay_for_job(self)
    unless res
      self.append_status_message "Not enough balance for this print job. #{mes}"
      # Continue printing is the logic to be supported
      # print_job.No_Balance!
      # print_job.save
      # return
    end

    [res, mes]
  end
  
  def workstation_warning?
    return false unless self.workstation.present?
    
    last_print_job = self.workstation.print_jobs.where.not(id: self.id).last
    return false unless last_print_job.present?
    return false if last_print_job.card_type.id.eql?self.card_type.id
    
    true
  end
  
  def drop_ship_address
    label_template = self.organization.label_templates.WSDL_Api_Formats.first
    label_template ||= LabelTemplate.global.WSDL_Api_Formats.first
    if label_template.present?
      job_addr = Mustache.render(label_template.to_address, self.context)
    else
      # Fallback of fallback
      job_addr = [
        params['FullName'],
        "#{params['Add1']} #{params['Add2']}",
        "#{params['Add3']}, #{params['Add4']} #{params['Postcode']}"
      ].join("\n")
    end
    address_to_print = [label_template.template, job_addr]
  end
  
  def append_context(params)
    self.context = self.context.merge(params)
    self.context
  end
  
  def address_type
    self.address.present? ? :print_job_address_drop_ship : :print_job_address_on_file
  end
  
  def delivery_address_alert
    country_name = "us"
    case self.address_type
    when :print_job_address_drop_ship
      if self.context["Postcode"].present?
        match_country_name = self.context["Postcode"].match(/.* (.*)/)
        country_name = match_country_name[1].downcase unless match_country_name.nil?
      end
    else
      # when :print_job_address_on_file
      addr = self.organization.address("primary")
      country_name = addr.country.downcase unless addr.nil?
    end

    return ["", nil] if (country_name.eql? "us" or country_name.eql? "usa")
    return ["Canada", :yellow] if country_name.eql? "canada"
    
    ["Overseas", :red]
  end

  def total_cards_shortcut
    (list_users.first.total_users if list_users.first.present?) || 0
  end
  
  def set_printed_date
      self.printed_at = Time.now.in_time_zone('Eastern Time (US & Canada)').strftime("%Y-%m-%d %H:%M:%S")
  end
  
  def special_handlings_tokens_shortcut
    card_template.extended_special_handlings_tokens || ""
  end
  
  def self.from_params(params)
    print_job = self.new(params.permit(:card_template_id, :shipping_provider_id, :status))
    print_job.add_users(params[:list_users]) if params[:list_users].present?

    # TODO (HR): DRY
    new_p.total_cards = new_p.total_cards_shortcut
    new_p.special_handlings = new_p.special_handlings_tokens_shortcut

    print_job
  end
  
  def self.from_wsdl(params, organization_id, card_template)
    # TODO (HR): I may need to set a flag indicating this job is coming from the WSDL API
    # It would generate an interesting report
    
    print_job = self.new({:organization_id => organization_id, :card_template_id => card_template.id, :shipping_provider_id => params[:ShipMethod], :number_of_copies => params[:NumOfCards]})
    
    if params['Add1'].present?
      # TODO (HR): the system should have label template an as well address template
      # Label template will be used to generate the label that is printer, while address template
      # will be used to generate the address that will be printed (that can be used in the label as
      # well as in a letter or email)
      label_template = print_job.organization.label_templates.WSDL_Api_Formats.first
      label_template ||= LabelTemplate.global.WSDL_Api_Formats.first
      if label_template.present?
        job_addr = Mustache.render(label_template.to_address, params)
      else
        # Fallback of fallback
        job_addr = [
          params['FullName'],
          "#{params['Add1']} #{params['Add2']}",
          "#{params['Add3']}, #{params['Add4']} #{params['Postcode']}"
        ].join("\n")
      end
      print_job.address = job_addr
    end

    print_job.context = print_job.context.merge(params)
    extra_params = {
      CARDFIRSTNAME: params[:FirstName],
      CARDLASTNAME: params[:LastName],
      CARDFULLNAME: params[:FullName],
      CARDADD1: params[:Add1],
      CARDADD2: params[:Add2],
      CARDADD3: params[:Add3],
      CARDADD4: params[:Add4],
      CARDPOSTCODE: params[:Postcode],
      CARDJOBNO: print_job.id,
      CARDCREF: params[:PaymentRef]
    }
    print_job.context = print_job.context.merge(extra_params)
    
    print_job
  end

  def self.from_reprint_params(print_job, reprint_params)
    new_p = self.new(:charge => false, :type_cd => 1)
    new_p.type_cd = 2 if reprint_params["only_letters"].eql?"true"
    new_p.charge = true if reprint_params["charge_again"].eql?"true"
    new_p.organization_id = print_job.organization_id
    new_p.card_template = print_job.card_template
    new_p.Scheduled!
    new_p.is_sample = print_job.is_sample
    new_p.address = print_job.address
    new_p.context = print_job.context
    new_p.number_of_copies = print_job.number_of_copies
    new_p.shipping_provider = print_job.shipping_provider
    new_p.workstation = print_job.workstation
    new_p.append_status_message "Reprint of job ##{print_job.id}"

    lu = new_p.list_users.first_or_initialize
    reprint_params["ids"].each do |ua_id|
      db_ua = UserDatum.find(ua_id)
      lu.user_datum.new(:data => db_ua.data, :card_template_id => print_job.card_template_id).save!
    end

    # TODO (HR): DRY
    new_p.total_cards = new_p.total_cards_shortcut
    new_p.special_handlings = new_p.special_handlings_tokens_shortcut
    
    new_p.save!
    new_p
  end
  
  def self.from_card_template(card_template)
    new_p = self.new(:charge => false, :type_cd => 0)
    new_p.organization_id = card_template.organization_id
    new_p.card_template = card_template
    new_p.Scheduled!
    new_p.is_sample = true
    new_p.append_status_message "Sample print job for card template ##{card_template.name}"

    lu = new_p.list_users.first_or_initialize
    lu.user_datum.new(:data => card_template.preview_data.data, :card_template_id => card_template.id).save!
    
    # TODO (HR): DRY
    new_p.total_cards = new_p.total_cards_shortcut
    new_p.special_handlings = new_p.special_handlings_tokens_shortcut
    
    new_p.save!
    new_p
  end
  
  def self.from_organization(organization)
    new_p = self.new(:charge => false, :type_cd => 3)
    new_p.organization_id = organization.id
    new_p.card_template = organization.give_me_a_card_template
    new_p.shipping_provider = nil
    new_p.Scheduled!
    new_p.append_status_message "Print Label for organization #{organization.name}"
    
    new_p.save!
    new_p
  end
  
  def self.summary
    jobs = PrintJob.includes(:organization).where(status_cd: 1).where(type_cd: 0)
    total_cards = 0
    total_jobs_per_shipping = [0, 0, 0]
    organizations = []
    jobs.each do |job|
      total_cards += job.total_cards
      if job.shipping_provider_id.present? and job.shipping_provider_id <= 3
        total_jobs_per_shipping[job.shipping_provider_id-1] += 1
      end
      organizations << job.organization.name
    end
    
    [total_cards, total_jobs_per_shipping, organizations.uniq]
  end
  
end
