module Legacy
  class CardCost < LegacyBase
    self.table_name = "CARDCOST"
    
    def self.migrate(from_organization_id, to_organization_id, migration_task = nil)
      log_level = 0
      all_costs = Legacy::CardCost.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id).order("COMPANY_NO, CARD_TYPE, NUM_OF_CARDS")

      # These extras have cost associated with it, that may need to be extracted 
      # from the card type cost
      slot_punch_cost = CardOption.where(element: "options").where(key: "slot_punch").first.costs.where(:organization_id => nil).first
      color_color_cost = CardOption.where(element: "options").where(key: "color").where(value: "colorcolor").first.costs.where(:organization_id => nil).first
      overlay_cost = SpecialHandling.where(name: "Holographic Overlay").first.costs.where(:organization_id => nil).first
      drop_ship_cost = SpecialHandling.where(name: "Drop Ship").first.costs.where(:organization_id => nil).first
      grommet_cost = SpecialHandling.where(name: "Grommet").first.costs.where(:organization_id => nil).first
      # hole_punch_cost = SpecialHandling.where(name: "Hole Punch").first.costs.where(:organization_id => nil).first
      
      cost_item_class = "CardType"
      range_low = 0
      range_high = 0
      previous_org = -1
      previous_card_type_id = -1

      all_costs.each do |cost|
        next if cost.COMPANY_NO < 0
        next unless cost.COST.present?
        org = nil
        unless cost.COMPANY_NO.eql?0
          org = Organization.where(:legacy_id => cost.COMPANY_NO).first
          org ||= Organization.where(:id => cost.COMPANY_NO).first
          # If couldn't find an organization, don't add this card type cost item
          Rails.logger.info("[CardTypeCost:migrate] Organization not found: #{cost.COMPANY_NO}") unless org.present?
          next unless org.present?
        end
        
        if cost.COMPANY_NO.eql?previous_org and cost.CARD_TYPE.eql?previous_card_type_id
          range_low = range_high + 1
          range_high = cost.NUM_OF_CARDS
        else
          previous_card_type_id = cost.CARD_TYPE
          previous_org = cost.COMPANY_NO
          range_low = 0
          range_high = cost.NUM_OF_CARDS
        end

        legacy_card_type = LegacyCardType.where(legacy_card_type_id: cost.CARD_TYPE).first
        unless legacy_card_type.present?
          MigrationTask.log_error_message(migration_task, org, "Card cost for an unknown card type (CardType: #{cost.CARD_TYPE})", :migration_log_warning)
          log_level = set_log_level(log_level, :migration_log_warning)
        end
        next unless legacy_card_type.present?
        
        # Find the default cost of it, if it is org based, to verify if
        if org.present? # and legacy_card_type.has_extras?
          default_price = Cost.where(organization_id: nil)
            .where(:costable_id => legacy_card_type.card_type_id)
            .where(:range_low => range_low)
            .where(:range_high => range_high)
            .where(:costable_type => cost_item_class).first
          
          create_flag = true
          if default_price.present? and cost.COST > default_price.value
            total_cost = default_price.value
            total_cost = total_cost + slot_punch_cost.value if legacy_card_type.slot_punch?
            total_cost = total_cost + color_color_cost.value if legacy_card_type.color_color?
            total_cost = total_cost + overlay_cost.value if legacy_card_type.overlay?
            total_cost = total_cost + drop_ship_cost.value if legacy_card_type.drop_ship?
            total_cost = total_cost + grommet_cost.value if legacy_card_type.grommet?
            # total_cost = total_cost + hole_punch_cost.value if legacy_card_type.hole_punch?
            
            if total_cost.eql?cost.COST
              create_flag = false
            end
          end
          
          MigrationTask.log_error_message(migration_task, org, "Card cost not being created. Value is the same as the sum of the default cost (CardType: #{cost.CARD_TYPE})", :migration_log_ok) unless create_flag
          next unless create_flag
        end

        org_id = org.present? ? org.id : nil
        new_cost = Cost.where(:organization_id => org_id)
          .where(:costable_id => legacy_card_type.card_type_id)
          .where(:range_low => range_low)
          .where(:range_high => range_high)
          .where(:costable_type => cost_item_class).first_or_initialize

        if new_cost.value.present?
          new_cost.value = cost.COST unless legacy_card_type.has_extras?
        else
          new_cost.value = cost.COST
        end
        new_cost.save!
      end
      
      log_level
    end
    
    def self.migrate_card_cost(company, migration_task = nil)
      self.migrate(company.COMPANY_NO, company.COMPANY_NO, migration_task)
    end
    
    def self.clean_default(from_organization_id, to_organization_id, migration_task = nil)
      all_card_types = CardType.all
      all_orgs = Organization.where("id >= ? and id <= ?", from_organization_id, to_organization_id)
      all_orgs.each do |org|
        message = ""
        all_card_types.each do |ct|
          org_cost_ct = Cost.where(organization_id: org.id)
            .where(:costable_type => "CardType")
            .where(:costable_id => ct.id)
            .order(range_low: :asc)
          next if org_cost_ct.empty?
          default_cost_ct = Cost.where(organization_id: nil)
            .where(:costable_type => "CardType")
            .where(:costable_id => ct.id)
            .order(range_low: :asc)
          
          # if the ranges are different
          next unless org_cost_ct.count.eql?default_cost_ct.count
          
          if org_cost_ct.to_a.map(&:range_low).eql?default_cost_ct.to_a.map(&:range_low) and
             org_cost_ct.to_a.map(&:range_high).eql?default_cost_ct.to_a.map(&:range_high) and
             org_cost_ct.to_a.map(&:value).eql?default_cost_ct.to_a.map(&:value)
             # Delete this org based card cost
             message += ", " if message.length > 0
             message += "#{ct.id}/#{ct.name}"
             org_cost_ct.delete_all
             next
          end
        end

        MigrationTask.log_error_message(migration_task, org, "Organization based Card cost being deleted. Both card ranges and price are equal for all items (Card ID/Name(s): #{message})", :migration_log_ok) if message.length > 0
      end
    end
    
    def self.clean_default_card_cost(company, migration_task = nil)
      self.clean_default(company.COMPANY_NO, company.COMPANY_NO, migration_task)
    end

  end
end