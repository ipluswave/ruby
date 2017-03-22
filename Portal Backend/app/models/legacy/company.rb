module Legacy
  class Company < LegacyBase
    self.table_name = "COMPANY"

    def self.migrate(from_organization_id, to_organization_id, migration_task = nil)
      no_parent_org_found = []
      us_country_helper = ISO3166::Country.find_country_by_name('united states')
      
      all_companies = Legacy::Company.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id).order("COMPANY_NO")
      all_companies.each do |company|
        self.migrate_company(company, us_country_helper, migration_task)
      end
    end
    
    def self.migrate_company(company, us_country_helper, migration_task = nil)
      log_level = 0
      return log_level if company.ACCOUNT_NO <= 0
      org = Organization.where(:legacy_id => company.COMPANY_NO).first
      if org.present?
        dup_org = Organization.where(:id => company.COMPANY_NO).first
        dup_org.delete if dup_org.present?
      end
      org ||= Organization.where(:id => company.COMPANY_NO).first_or_initialize
      org.id ||= company.COMPANY_NO

      # Set it to as running in the Legacy System if no value yet and ID is in the legacy range
      org.Legacy! if (!org.system_cd.present? and org.is_legacy?)
      org.name ||= company.COMPANY_NAME
      
      my_account = Legacy::Account.where("ACCOUNT_NO = ?", company.ACCOUNT_NO).first
      if my_account.present?
        if company.COMPANY_NO != company.ACCOUNT_NO
          org.parent_organization_id = company.ACCOUNT_NO
        else
          org.legacy_balance = my_account.BALANCE if my_account.BALANCE.present?
          org.overdraft = (my_account.OVERDRAFT.present?) ? my_account.OVERDRAFT : 0
        end
      else
        MigrationTask.log_error_message(migration_task, org, "Company '#{org.name}' has a different Account Number (#{company.ACCOUNT_NO}) and it wasn't found", :migration_log_warning)
        log_level = set_log_level(log_level, :migration_log_warning)
      end
      org.save!
      
      migration_task.organizations.push(org)
      contact = self.migrate_contact(org, company)
      addr = self.migrate_address(org, contact, us_country_helper, company)
      log_level
    end
    
    def self.migrate_contact(organization, company)
      return nil if (!company.COMP_EMAIL.present? and !company.COMPANY_CONTACT.present?)
      contact = organization.contacts.where(:email => company.COMP_EMAIL).first if company.COMP_EMAIL.present?
      contact ||= organization.contacts.where(:full_name => company.COMPANY_CONTACT).first if company.COMPANY_CONTACT.present?
      contact ||= organization.contacts.new unless contact.present?
      contact.update_attributes({
        :full_name => company.COMPANY_CONTACT,
        :email => company.COMP_EMAIL,
        :phone_number => company.COMP_PHONE,
        :fax_number => company.COMP_FAX,
        })
      contact.save!
      contact
    end

    def self.migrate_address(organization, contact, us_country_helper, company)
      return nil unless company.ADD1.present?
      addr = organization.addresses.where(:label => 'Primary').first
      addr ||= organization.addresses.new unless addr.present?
      is_us_state = us_country_helper.subdivisions[company.ADD4].present?
      addr.update_attributes({
        :label => 'Primary',
        :organization_name => organization.name,
        :address1 => company.ADD1,
        :address2 => company.ADD2,
        :city => company.ADD3,
        :state => company.ADD4,
        :zip_code => company.POSTCODE,
        :country => is_us_state ? "US" : company.ADD4,
        :primary => true
        })
      addr.contact_id = contact.id if contact.present?
      addr.save!
      addr
    end
    
  end
end
