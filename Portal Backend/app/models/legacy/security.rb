module Legacy
  class Security < LegacyBase
    self.table_name = "SECURITY"
    
    def self.migrate(from_organization_id, to_organization_id, migration_task = nil)
      # Delete current users
      Legacy::Security.clean_users(from_organization_id, to_organization_id)

      all_users = Legacy::Security.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id).order("COMPANY_NO")
      all_users.each do |user|
        self.migrate_user(user, migration_task)
      end
    end
    
    def self.migrate_security(company, migration_task = nil)
      log_level = 0

      # Delete current users
      Legacy::Security.clean_users(company.id, company.id)

      all_users = Legacy::Security.where("COMPANY_NO = ?", company.COMPANY_NO)
      all_users.each do |user|
        new_log_level = self.migrate_user(user, migration_task)
        log_level = set_log_level(log_level, new_log_level)
      end
      log_level
    end
    
    def self.migrate_user(user, migration_task = nil)
      log_level = 0
      org = Organization.where(:id => user.COMPANY_NO).first
      org ||= Organization.where(:legacy_id => user.COMPANY_NO).first
      return log_level unless org.present?
      new_user = org.users.where(:email => user.EMAIL.downcase).first_or_initialize
      new_user.update_attributes({
        :email => user.EMAIL.downcase,
        :pin => user.PIN
        })
      unless new_user.encrypted_password.present?
        new_password = SecureRandom.uuid
        new_user.password = new_password
        new_user.password_confirmation = new_password
      end
      new_user.add_role(:admin)
      begin
        new_user.save!
      rescue Exception => e
        unless user.PIN.eql?"A1234"
          MigrationTask.log_error_message(migration_task, org, "Invalid user. Exception: #{e.to_s}. ID (#{new_user.id}), Email (#{new_user.email})", :migration_log_warning)
          log_level = set_log_level(log_level, :migration_log_warning)
        end
      end
      log_level
    end
    
    def self.clean_users(from_organization_id, to_organization_id)
      User.where('organization_id >= ? and organization_id <= ?', from_organization_id, to_organization_id).delete_all
    end

  end
end
