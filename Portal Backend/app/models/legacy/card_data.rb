require 'open3'

module Legacy
  class CardData < LegacyBase
    self.table_name = "CARDDATA"

    def self.migrate(from_organization_id, to_organization_id, migration_task = nil)
      all_cards = Legacy::CardData.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id)
      all_cards.each do |card|
        self.migrate_card(card, migration_task)
      end
    end

    def self.migrate_card(card, migration_task = nil)
      log_level = 0
      return log_level if card.COMPANY_NO <= 0

      # Find Organization
      org = Organization.where(:legacy_id => card.COMPANY_NO).first
      org ||= Organization.where(:id => card.COMPANY_NO).first
      
      # If couldn't find an organization, don't migrate this card template
      unless org.present?
        MigrationTask.log_error_message(migration_task, org, "Card template (RefNum:#{card.CARD_REF_NUM}) from unknown Organization (ID:#{card.COMPANY_NO})", :migration_log_error)
        log_level = set_log_level(log_level, :migration_log_error)
      end
      return log_level unless org.present?
      
      card_template_cousing = CardTemplate.where(id: card.CARD_REF_NUM).where.not(organization_id: org.id).first
      if card_template_cousing.present?
        MigrationTask.log_error_message(migration_task, org, "Card template (RefNum:#{card.CARD_REF_NUM}) exist for another Organization (ID:#{card_template_cousing.organization_id})", :migration_log_warning)
        log_level = set_log_level(log_level, :migration_log_warning)
        new_card = org.shared_templates.new
        new_card.card_template_id = card_template_cousing.id
        new_card.save!
      end
      return log_level if card_template_cousing.present?

      # Create an empty template with the correct id:
      card_template = org.card_templates.where(id: card.CARD_REF_NUM).first_or_initialize
      legacy_card_type = LegacyCardType.where(legacy_card_type_id: card.CARD_TYPE).first
      unless legacy_card_type.present?
        MigrationTask.log_error_message(migration_task, org, "Card template (RefNum:#{card.CARD_REF_NUM}) from unknown LegacyCardType (ID:#{card.CARD_TYPE})", :migration_log_error)
        log_level = set_log_level(log_level, :migration_log_error)
      end
      return log_level unless legacy_card_type.present?
      
      if legacy_card_type.name.match(/Not found/)
        MigrationTask.log_error_message(migration_task, org, "Card template (RefNum:#{card.CARD_REF_NUM}) from unknown LegacyCardType (ID:#{card.CARD_TYPE}) being migrated as White PVC", :migration_log_warning)
      end
      
      card_template.name = "Default Card Name. ID: #{card.CARD_REF_NUM}"
      card_template.card_type = legacy_card_type.card_type if legacy_card_type.present?
      card_template.Approved!
      card_template.save!
      
      slot_punch = legacy_card_type.slot_punch? ? true : false
      color_color = legacy_card_type.color_color? ? true : false
      mag_stripe = (legacy_card_type.card_type.id.eql?2) ? true : false
      if mag_stripe
        MigrationTask.log_error_message(migration_task, org, "Card template (RefNum:#{card.CARD_REF_NUM}) is mag stripe. Please check tracks for variable attributes.", :migration_log_warning)
        log_level = set_log_level(log_level, :migration_log_warning)
      end
      
      mig_url = "#{ENV['card_template_migrate_root']}?card_ref_num=#{card.CARD_REF_NUM}&slot_punch=#{slot_punch}&color_color=#{color_color}&mag_stripe=#{mag_stripe}&upload=true&show_previews=true&_t=#{Time.now.to_i}"
      Rails.logger.info("Migrating template through: #{mig_url}")
      mig_image_path = "#{Rails.root.to_s}/tmp/cards/cardtemplate-#{Time.now.to_i}-#{card.CARD_REF_NUM}.jpg"

      begin
        screenshot = Screenshot.new
        page = screenshot.capture(mig_url, mig_image_path, 1024, 1024, true, 60)

        html = Nokogiri::HTML(page[2])
        if(html.css('div#messages')[0].present?)
          messages_json = JSON.parse(html.css('div#messages')[0].text)

          status = messages_json["status"]
          messages_json["messages"].each do |m|
            m_status = MigrationLog.status_to_symbol(m["status"])
            MigrationTask.log_error_message(migration_task, org, "Card template #{card.CARD_REF_NUM}: #{m['message']}", m_status)
            log_level = set_log_level(log_level, m_status)
          end

          status = messages_json["status"]
          m_status = MigrationLog.status_to_symbol(status)
          MigrationTask.log_error_message(migration_task, org, "Migration of card template #{card.CARD_REF_NUM} finished with status #{status}", m_status)
          log_level = set_log_level(log_level, m_status)
        elsif page.first
          # At least finished successfully
          MigrationTask.log_error_message(migration_task, org, "Migration of card template #{card.CARD_REF_NUM} finished successfully", :migration_log_ok)
        else
          # Finished with error
          MigrationTask.log_error_message(migration_task, org, "Migration of card template #{card.CARD_REF_NUM} finished with an unspecified error", :migration_log_error)
          log_level = set_log_level(log_level, :migration_log_error)
        end
        
        screenshot.reset_session
      rescue Exception => e
        MigrationTask.log_error_message(migration_task, org, "Exception during the migration of card template: #{card.CARD_REF_NUM}. Message: #{e.message}", :migration_log_error)
        log_level = set_log_level(log_level, :migration_log_error)
      end

      # Evaluate other attributes bundled in the LegacyCardType
      card_template = org.card_templates.where(id: card.CARD_REF_NUM).first
      if legacy_card_type.overlay?
        ol = SpecialHandling.where(name: 'Holographic Overlay').first
        card_template.special_handlings.push(ol) if (ol.present? && card_template.special_handlings.where(id: ol.id).empty?)
      end
      
      to_value = legacy_card_type.color_color? ? "colorcolor" : "colorblack"
      if card_template.double_sided?
        cur_value = card_template.option_key("color")
        unless cur_value.eql?to_value
          card_template.set_option_key("color", to_value)
          card_template.save!
        end
      end
      
      if legacy_card_type.drop_ship?
        ds = SpecialHandling.where(name: 'Drop Ship').first
        card_template.special_handlings.push(ds) if (ds.present? && card_template.special_handlings.where(id: ds.id).empty?)
      end
      
      unless legacy_card_type.accessories.eql?"NONE"
        acc = SpecialHandling.where(name: legacy_card_type.accessories).first
        card_template.special_handlings.push(acc) if (acc.present? && card_template.special_handlings.where(id: acc.id).empty?)
      end
      
      if legacy_card_type.grommet?
        grom = SpecialHandling.where(name: 'Grommet').first
        card_template.special_handlings.push(grom) if (grom.present? && card_template.special_handlings.where(id: grom.id).empty?)
      end
      
      if legacy_card_type.hole_punch?
        hp = SpecialHandling.where(name: 'Hole Punch').first
        card_template.special_handlings.push(hp) if (hp.present? && card_template.special_handlings.where(id: hp.id).empty?)
      end

      fonts = (card_template.used_fonts('front', true) + card_template.used_fonts('back', true)).uniq
      fonts.each do |font_name|
        f = Font.where(name: font_name).first_or_initialize
        next if f && f.global?

        # In case this is a new font
        f.save!
      
        # TODO (HR): Get test responses for fc-match calls on ubuntu
        out, err, st = Open3.capture3('fc-match', font_name)
        
        unless out.match(font_name)
          MigrationTask.log_error_message(migration_task, org, "Organization based not font: #{font_name}. FC-match response: #{out}", :migration_log_error)
          log_level = set_log_level(log_level, :migration_log_error)
        end
      
        if !f.global? && org.fonts.where(id: f.id).empty?
          org.fonts.push f
        end
      end
      
      if card.LETTER.present?
        card_template_letter = org.letter_templates.where(:name => "Default letter").first_or_initialize
        card_template_letter.name = "Default letter"
        card_template_letter.template = "COPY FROM ORIGINAL" if card_template_letter.template.blank?
        card_template_letter.save!
        
        MigrationTask.log_error_message(migration_task, org, "This card template (ID: #{card_template.id}) has a letter that needs to be copied manually.", :migration_log_warning)
        log_level = set_log_level(log_level, :migration_log_warning)
        
        if card_template.option_key("letter_id").present?
          card_template.set_option_key("letter_id", card_template_letter.id)
        else
          card_template.options << {"key"=>"letter_id", "value"=>"#{card_template_letter.id}"}
        end
        card_template.save!
      end
      
      log_level
    end

    def self.migrate_company_card(company, migration_task = nil)
      log_level = 0
      all_cards = Legacy::CardData.where("COMPANY_NO = ?", company.COMPANY_NO)
      all_cards.each do |card|
        new_log_level = self.migrate_card(card, migration_task)
        log_level = set_log_level(log_level, new_log_level)
      end

      org = Organization.where(id: company.COMPANY_NO).first
      if org && org.card_templates.count <= 0
        MigrationTask.log_error_message(migration_task, org, "Organization '#{org.name}' (ID:#{org.id}) doesn't have any migrated card templates ", :migration_log_warning)
        log_level = set_log_level(log_level, :migration_log_warning)
      end
      
      log_level
    end
    
    def self.backup_card_template_image(from_organization_id, to_organization_id)

      # This code was used during the migration and right after the migration
      # [HR] Delete if not used after 06/10/2017
      # client = Savon::Client.new(wsdl: ENV['legacy_preview_root'])
      # 
      # all_cards = Legacy::CardData.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id)
      # all_cards.each do |card|
      #   begin
      #     # find org and user
      #     org = Organization.where(id: card.COMPANY_NO).first
      #     next unless org.present?
      #     
      #     wsdl_user = org.users.first
      #     next unless wsdl_user.present?
      #     
      #     # get basic params and replaceable attributes
      #     basic_params = { "email" => wsdl_user.email.upcase, "CompanyPIN" => wsdl_user.pin, "CardRefNum" => card.CARD_REF_NUM, "CardWidth" => 400}
      #     front_side_params = UserDatum.mock_wsdl_user_params(nil, basic_params.merge({"CardSide" => 0}))
      #     back_side_params = UserDatum.mock_wsdl_user_params(nil, basic_params.merge({"CardSide" => 1}))
      #     
      #     # get preview image (front & back)
      #     front_preview_legacy_image = client.call(:preview_card, message: front_side_params)
      #     front_preview_legacy_image = front_preview_legacy_image.to_hash[:preview_card_response][:return]
      #     if front_preview_legacy_image.length.eql?2
      #       # save image in /bucket/card_template/legacy/ID-front-error.txt
      #       path = "#{Rails.root.to_s}/tmp/legacy_preview/#{card.CARD_REF_NUM}-front-error.txt"
      # 
      #       image = File.new(path, "wb")
      #       image.write("Error from #{ENV['legacy_preview_root']}: #{front_preview_legacy_image}")
      #     else
      #       # save image in /bucket/card_template/legacy/ID-front.jpg
      #       path = "#{Rails.root.to_s}/tmp/legacy_preview/#{card.CARD_REF_NUM}-front.jpg"
      #       image_data = Base64.decode64(front_preview_legacy_image)
      # 
      #       image = File.new(path, "wb")
      #       image.write(image_data)
      #     end
      #     
      #     # get preview image (front & back)
      #     back_preview_legacy_image = client.call(:preview_card, message: back_side_params)
      #     back_preview_legacy_image = back_preview_legacy_image.to_hash[:preview_card_response][:return]
      # 
      #     if back_preview_legacy_image.length.eql?2
      #       # save image in /bucket/card_template/legacy/ID-back-error.txt
      #       path = "#{Rails.root.to_s}/tmp/legacy_preview/#{card.CARD_REF_NUM}-back-error.txt"
      # 
      #       image = File.new(path, "wb")
      #       image.write("Error from #{ENV['legacy_preview_root']}: #{back_preview_legacy_image}")
      #     else
      #       # save image in /bucket/card_template/legacy/ID-back.jpg
      #       path = "#{Rails.root.to_s}/tmp/legacy_preview/#{card.CARD_REF_NUM}-back.jpg"
      #       image_data = Base64.decode64(back_preview_legacy_image)
      # 
      #       image = File.new(path, "wb")
      #       image.write(image_data)
      #     end
      #   rescue Exception => e
      #     Rails.logger(:error, "Exception during backup of Card (ID:#{card.CARD_REF_NUM}), Org (ID:#{card.COMPANY_NO})")
      #   end
      #   
      # end
    end

  end
end
