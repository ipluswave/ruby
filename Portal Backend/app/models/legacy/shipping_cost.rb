module Legacy
  class ShippingCost < LegacyBase
    self.table_name = "SHIPCOST"
    
    def self.migrate(from_organization_id, to_organization_id, migration_task = nil)
      # Clean existing to create with the correct range
      Cost.where("organization_id >= ?", from_organization_id).where("organization_id <= ?", to_organization_id).delete_all

      all_costs = Legacy::ShippingCost.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id).order("COMPANY_NO, SHIP_METHOD, NUM_OF_CARDS")
      shipping_provider_class = "ShippingProvider"
      range_low = 0
      range_high = 0
      previous_cost_org = -1
      previous_shipping_provider_id = 0
      previous_cost = nil
      all_costs.each do |cost|
        next if cost.COMPANY_NO < 0
        org = nil
        unless cost.COMPANY_NO.eql?0
          org = Organization.where(:legacy_id => cost.COMPANY_NO).first
          org ||= Organization.where(:id => cost.COMPANY_NO).first

          # If couldn't find an organization, don't add this shipping cost item
          MigrationTask.log_error_message(migration_task, org, "Shipping cost for an unknown organization (ID: #{cost.COMPANY_NO}).", :migration_log_warning) unless org.present?
          next unless org.present?

          org = org.id if org.present?
        end
        
        if cost.COMPANY_NO.eql?previous_cost_org and cost.SHIP_METHOD.eql?previous_shipping_provider_id
          range_low = cost.NUM_OF_CARDS
          range_high = 100
          if previous_cost
            previous_cost.range_high = cost.NUM_OF_CARDS - 1
            previous_cost.save!
          end
        else
          previous_cost_org = cost.COMPANY_NO
          previous_shipping_provider_id = cost.SHIP_METHOD
          range_low = cost.NUM_OF_CARDS
          range_high = cost.NUM_OF_CARDS
        end
        
        new_cost = Cost.where(:organization_id => org)
          .where(:costable_id => cost.SHIP_METHOD)
          .where(:range_low => range_low)
          .where(:range_high => range_high)
          .where(:costable_type => shipping_provider_class).first_or_initialize
        new_cost.value = cost.COST
        new_cost.save!
        
        previous_cost = new_cost
      end
    end
    
    def self.migrate_shipping_cost(company, migration_task = nil)
      self.migrate(company.COMPANY_NO, company.COMPANY_NO, migration_task)
    end

    def self.clean_default(from_organization_id, to_organization_id, migration_task = nil)
      all_shipping_providers = ShippingProvider.all
      all_orgs = Organization.where("id >= ? and id <= ?", from_organization_id, to_organization_id)
      all_orgs.each do |org|
        message = ""
        all_shipping_providers.each do |sp|
          org_cost_sp = Cost.where(organization_id: org.id)
            .where(:costable_type => "ShippingProvider")
            .where(:costable_id => sp.id)
            .order(range_low: :asc)
          next if org_cost_sp.empty?
          default_cost_sp = Cost.where(organization_id: nil)
            .where(:costable_type => "ShippingProvider")
            .where(:costable_id => sp.id)
            .order(range_low: :asc)
          
          # if the ranges are different
          next unless org_cost_sp.count.eql?default_cost_sp.count
          
          if org_cost_sp.to_a.map(&:range_low).eql?default_cost_sp.to_a.map(&:range_low) and
             org_cost_sp.to_a.map(&:range_high).eql?default_cost_sp.to_a.map(&:range_high) and
             org_cost_sp.to_a.map(&:value).eql?default_cost_sp.to_a.map(&:value)
             # Delete this org based shipping cost
             message += ", " if message.length > 0
             message += sp.name
             org_cost_sp.delete_all
           end
        end
        
        MigrationTask.log_error_message(migration_task, org, "Organization based Shipping cost being deleted. Both shipping ranges and price are equal for all items (ShippingProvider(s): #{message})", :migration_log_ok) if message.length > 0
      end
    end
    
    def self.clean_default_shipping_cost(company, migration_task = nil)
      self.clean_default(company.COMPANY_NO, company.COMPANY_NO, migration_task)
    end

  end
  
end
