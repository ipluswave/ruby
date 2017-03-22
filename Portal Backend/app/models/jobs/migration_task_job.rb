module Jobs
  class MigrationTaskJob
    attr_accessor :migration_task_id

    def initialize(options)
      self.migration_task_id = options[:migration_task_id]
    end
    
    def max_run_time
      172800 # seconds
    end

    def perform_legacy
      migration_task = MigrationTask.find(self.migration_task_id)

      begin
        # 1. migration:companies
        Legacy::Company.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)
        
        # 2. migration:users
        Legacy::Security.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)

        # The items 3 and 4 are static and not company related
        # 3. migration:card_types
        # 4. migration:special_handlings
        
        # 5. migration:shipping_costs
        Legacy::ShippingCost.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)
        Legacy::ShippingCost.clean_default(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)

        # Migrage Card cost
        # 6.0 Delete current card costs $ delete from costs where costable_type = ‘CardType’
        # 	- Maybe I don’t need this
        # 6.1 Make sure the following Special Handling are named correctly:
        # 	- LOTO grommet -> Grommet
        # 	- LOTO with hole punch -> Hole Punch
        # 	- Individual Mailing -> Drop Ship
        # 6.2 Make sure the following default costs exists:
        # 	- Grommet: $1.00
        # 	- Hole Punch: no cost
        # 	- Drop Ship: $1.25
        # 	- Holographic Overlay: $1.10
        # 	- slot punch: $0.55
        # 	- color color: $0.55
        # 6.1 migration:card_costs
        Legacy::CardCost.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)
        Legacy::CardCost.clean_default(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)

        # 7. migration:transactions
        Legacy::Transaction.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)
        
        # 8. migration:card
        Legacy::CardData.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)

        migration_task.migration_logs.new(:message => "Finished successfully!").save!
        migration_task.Finished!
        migration_task.save!
      rescue Exception => e
        ml = migration_task.migration_logs.new(:message => "Finished with failure! Exception: #{e.message}")
        ml.migration_log_error!
        ml.save!
        migration_task.Failed!
        migration_task.save!
      end
    end
    
    def perform
      migration_task = MigrationTask.find(self.migration_task_id)
      us_country_helper = ISO3166::Country.find_country_by_name('united states')

      all_companies = Legacy::Company.where("COMPANY_NO >= ? and COMPANY_NO <= ?", migration_task.from_organization_id, migration_task.to_organization_id).order("COMPANY_NO")
      all_companies.each do |company|
        begin
          org = Organization.where(id: company.COMPANY_NO).first
          if org && org.NewSystem?
            MigrationTask.log_error_message(migration_task, org, "Organization '#{org.name}' (ID:#{org.id}) has already been migrated to the new system.", :migration_log_ok)
            next
          end
          
          log_level = []
          stopped_at = "Organization"
          log_level << Legacy::Company.migrate_company(company, us_country_helper, migration_task)
          
          # In case this is the first time this company is migrated
          org = Organization.where(id: company.COMPANY_NO).first

          stopped_at = "User"
          log_level << Legacy::Security.migrate_security(company, migration_task)

          stopeed_at = "Shipping Cost"
          Legacy::ShippingCost.migrate_shipping_cost(company, migration_task)
          stoppped_at = "Cleaning Shipping Cost"
          Legacy::ShippingCost.clean_default_shipping_cost(company, migration_task)

          stopped_at = "Card Cost"
          log_level << Legacy::CardCost.migrate_card_cost(company, migration_task)
          stoppped_at = "Cleaning Card Cost"
          Legacy::CardCost.clean_default_card_cost(company, migration_task)

          # Financial Transactions needs to be migrated sequentially
          # stopped_at = "Financial Transactions"
          # log_level << Legacy::Transaction.migrate_financial_transaction(company, migration_task)
          
          stopped_at = "Card Template"
          log_level << Legacy::CardData.migrate_company_card(company, migration_task)

          # This message is not necessary here anymore
          # migration_task.migration_logs.new(:message => "Organization '#{company.COMPANY_NAME}' (ID:#{company.COMPANY_NO}) finished successfully!").save!
          next unless org.present?
          
          org.migration_status_cd = log_level.max
          org.save!

        rescue Exception => e
          ml = migration_task.migration_logs.new(:message => "Error processing Company '#{company.COMPANY_NAME}' (ID:#{company.COMPANY_NO}). Stopped at: #{stopped_at}. Exception: #{e.message}")
          ml.migration_log_error!
          ml.save!
        end
      end
      
      begin
        # Migrate all financial Transactions sequentially
        # 7. migration:transactions
        stopped_at = "Financial Transactions"
        Legacy::Transaction.migrate(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)

        stopped_at = "Financial Transactions: check legacy balance"
        Legacy::Transaction.check_legacy_balance(migration_task.from_organization_id, migration_task.to_organization_id, migration_task)
        
        migration_task.migration_logs.new(:message => "Finished successfully!").save!
        migration_task.Finished!
        migration_task.save!
        
        migration_task.notify
      rescue Exception => e
        ml = migration_task.migration_logs.new(:message => "Error importing Financial Transactions. Stopped at: #{stopped_at}. Exception: #{e.message}")
        ml.migration_log_error!
        ml.save!

        migration_task.Failed!
        migration_task.save!
      end
    end
    
    def self.enqueue(options, queue = 'migration')
      new_job = MigrationTaskJob.new(options)
      Delayed::Job.enqueue queue: queue, payload_object: new_job, run_at: Time.now
    end
  end
  
end
