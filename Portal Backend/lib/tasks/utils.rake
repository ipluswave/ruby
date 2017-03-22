namespace :utils do
  desc "Migrate Companies from the Legacy DB"
  task :fix_financial_transaction_sub_type_id => :environment  do |t, args|
    FinancialTransaction.find_each(batch_size: 5000) do |ft|
      next if ft.financial_transaction_sub_type.present?
      case ft.operation_cd
      when 0 # Credit
        # Set with Credit by check
        ft.financial_transaction_sub_type_id = 1
        ft.save!
      when 1 # Debit
        # Set with Print Job debit
        ft.financial_transaction_sub_type_id = 4
        ft.save!
      end
    end
  end

  desc "Review Organization Status Active or Inactive"
  task :review_organization_status => :environment  do |t, args|
    Organization.review_organization_status
  end
  
  desc "Break Financial Transaction value in Credit & Debit"
  task :break_financial_transaction_value_in_credit_debit => :environment  do |t, args|
    FinancialTransaction.break_value_in_credit_debit
  end
  
  desc "Migrate Card Template template fields"
  task :migrate_card_template_template_fields => :environment do |t, args|
    fixed_count = 0
    correct_count = 0
    CardTemplate.find_each(batch_size: 5000) do |c|
      new_template_fields = []
      c.template_fields.each do |tf|
        unless tf['label'].present?
          tf['label'] = tf['token'].gsub('_', ' ')
          new_template_fields << tf
          fixed_count = fixed_count + 1
        else
          new_template_fields << tf
          correct_count = correct_count + 1
        end
      end

      c.template_fields = new_template_fields
      c.save!
    end
  end

  # desc "Card Templaes with slot_punch:none"
  # task :card_templates_slot_punch_none => :environment do |t, args|
  #   count_print_jobs = 0
  #   count_cards = 0
  #   org_total = {}
  #   CardTemplate.find_each(batch_size: 5000) do |c|
  #     c.options.each do |co|
  #       next unless (co["key"].eql?"slot_punch" and co["value"].eql?"none")
  #       next if c.print_jobs.empty?
  #       
  #       c.print_jobs.each do |pj|
  #         next if pj.is_sample?
  #         next unless pj.financial_transaction.present?
  #         
  #         count_print_jobs += 1
  #         count_cards += pj.total_cards
  #         org_total[c.organization_id] = 0 unless org_total[c.organization_id].present?
  #         org_total[c.organization_id] += pj.total_cards
  #         puts "Print Job ID: #{pj.id} - Organization: #{pj.organization.name} - Total Cards: #{pj.total_cards}"
  #       end
  #     end
  #   end
  #   
  #   puts "Total print jobs: #{count_print_jobs}"
  #   puts "Total cards: #{count_cards}"
  #   
  #   org_total.each do |k,v|
  #     org = Organization.find(k)
  #     ft = org.financial_transactions.new
  #     ft.credit = v * 0.55
  #     ft.description = "Credit for wrong slot punch charges"
  #     ft.financial_transaction_sub_type = FinancialTransactionSubType.find(7)
  #     ft.save!
  #   end
  # end

  desc "Fix Card Template reference on User Data model"
  task :fix_card_template_reference_on_user_data_model => :environment do |t, args|
    UserDatum.find_each(batch_size: 5000) do |ud|
      next if ud.card_template_id.present?
      if ud.data["CardRefNum"].present?
        ud.card_template_id = ud.data["CardRefNum"].to_i
        ud.save!
      elsif ud.list_user_id.present?
        begin
          ud.card_template_id = ud.list_user.print_job.card_template_id
          ud.save!
        rescue
        end
      end
    end
  end
  
  desc "Update print job special tokens"
  task :update_print_jobs => :environment do |t, args|
    PrintJob.where(status_cd: 1).each do |pj|
      pj.special_handlings = pj.card_template.extended_special_handlings_tokens
      pj.save!
    end
  end

  # desc "ABB cards fix"
  # task :abb_cards_fix, [:from_organization_id, :to_organization_id] => :environment do |t, args|
  #   exit unless args.from_organization_id.present? and args.to_organization_id.present?
  #   total_cards = 0
  #   total_wrong = 0
  # 
  #   all_cards = CardTemplate.where('organization_id >= ?', args.from_organization_id).where('organization_id <= ?', args.to_organization_id).order(organization_id: :asc)
  #   all_cards.each do |c|
  #     wrong = false
  #     c.template_fields.each do |tf|
  #       if tf["type"].eql?"normal"
  #         wrong = true
  #         puts tf.to_s
  #         tf["type"]="text"
  #       end
  #     end
  #     if wrong
  #       total_wrong += 1
  #       c.save!
  #       puts "Organization (ID:#{c.organization_id}/Name:#{c.organization.name})Card Template (ID:#{c.id}/Name:#{c.name})"
  #     end
  #     
  #     total_cards += 1
  #   end
  #   
  #   puts "Total Wrong: #{total_wrong}/#{total_cards}"
  # end

  # desc "ABB Arial Black bold fix"
  # task :abb_arial_black_bold_fix, [:from_organization_id, :to_organization_id] => :environment do |t, args|
  #   exit unless args.from_organization_id.present? and args.to_organization_id.present?
  #   total_changed = 0
  #   total = 0
  #   
  #   all_cards = CardTemplate.where('organization_id >= ?', args.from_organization_id).where('organization_id <= ?', args.to_organization_id).order(organization_id: :asc)
  #   all_cards.each do |c|
  #     front_changed = false
  #     back_changed = false
  #     
  #     if c.front_data.match(/\"fontWeight\":\"bold\",\"fontFamily\":\"Arial Black\"/)
  #       puts "[1]Changing FrontData Template (ID:#{c.id}/Name:#{c.name})"
  #       front_changed = true
  #       c.front_data = c.front_data.gsub("\"fontWeight\":\"bold\",\"fontFamily\":\"Arial Black\"", "\"fontWeight\":\"normal\",\"fontFamily\":\"Arial Black\"")
  #     end
  #     
  #     if c.front_data.match(/\"fontWeight\":\"bold\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"/)
  #       puts "[2]Changing FrontData Template (ID:#{c.id}/Name:#{c.name})"
  #       front_changed = true
  #       c.front_data = c.front_data.gsub("\"fontWeight\":\"bold\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"", "\"fontWeight\":\"normal\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"")
  #     end
  # 
  #     if c.back_data.match(/\"fontWeight\":\"bold\",\"fontFamily\":\"Arial Black\"/)
  #       puts "[1]Changing BackData Template (ID:#{c.id}/Name:#{c.name})"
  #       back_changed = true
  #       c.back_data = c.back_data.gsub("\"fontWeight\":\"bold\",\"fontFamily\":\"Arial Black\"", "\"fontWeight\":\"normal\",\"fontFamily\":\"Arial Black\"")
  #     end
  # 
  #     if c.back_data.match(/\"fontWeight\":\"bold\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"/)
  #       puts "[2]Changing FrontData Template (ID:#{c.id}/Name:#{c.name})"
  #       back_changed = true
  #       c.back_data = c.back_data.gsub("\"fontWeight\":\"bold\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"", "\"fontWeight\":\"normal\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"")
  #     end
  # 
  #     if front_changed || back_changed
  #       c.save!
  #       total_changed += 1
  #     else
  #       if !(
  #         c.front_data.match(/\"fontWeight\":\"normal\",\"fontFamily\":\"Arial Black\"/) or
  #         c.back_data.match(/\"fontWeight\":\"normal\",\"fontFamily\":\"Arial Black\"/) or
  #         c.front_data.match(/\"fontWeight\":\"normal\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"/) or
  #         c.back_data.match(/\"fontWeight\":\"normal\",\"fontStyle\":\"\",\"fontFamily\":\"Arial Black\"/)
  #         )
  #         if (
  #           c.front_data.match(/\"fontFamily\":\"Arial Black\"/) or
  #           c.back_data.match(/\"fontFamily\":\"Arial Black\"/)
  #           )
  #         end
  #       end
  #     end
  #     
  #     total += 1
  #   end
  #   
  #   puts "Total changed: #{total_changed}"
  #   puts "Total: #{total}"
  # end

  # desc "Placeholder token fix"
  # task :placeholder_token_fix, [:from_organization_id, :to_organization_id] => :environment do |t, args|
  #   exit unless args.from_organization_id.present? and args.to_organization_id.present?
  #   total_changed = 0
  #   total = 0
  # 
  #   all_cards = CardTemplate.where('organization_id >= ?', args.from_organization_id).where('organization_id <= ?', args.to_organization_id).order(organization_id: :asc)
  #   all_cards.each do |c|
  #     fixed = false
  #     c.template_fields.each do |tf|
  #       if tf["token"].eql?"normal"
  #         puts "[NORMAL] Organization (ID:#{c.organization_id}) #{c.organization.name} - Template ID: #{c.id} - Name: #{c.name} with type:'normal'"
  #         # fixed = true
  #       end
  #       
  #       if tf["type"].eql?"text" and tf["token"].eql?"placeholder"
  #         puts "[TEXT] Organization (ID:#{c.organization_id}) #{c.organization.name} - Template ID: #{c.id} - Name: #{c.name} with text:placeholder"
  #         tf["type"] = "placeholder"
  #         tf["token"] = "placeholder"
  #         fixed = true
  #       end
  #       
  #       if tf["type"].eql?"text" and tf["token"].eql?""
  #         puts "[EMPTY] Organization (ID:#{c.organization_id}) #{c.organization.name} - Template ID: #{c.id} - Name: #{c.name} with type:''"
  #         tf["type"] = "placeholder"
  #         tf["token"] = "placeholder"
  #         tf["label"] = "~placeholder~"
  #         fixed = true
  #       end
  #     end
  #     
  #     if fixed
  #       c.save!
  #       total_changed += 1
  #     end
  #     
  #     total += 1
  #   end
  #   
  #   puts "Total changed: #{total_changed}"
  #   puts "Total: #{total}"
  # end

  # desc "Remove Placeholder token, if last"
  # task :remove_placeholder_token_if_last, [:from_organization_id, :to_organization_id] => :environment do |t, args|
  #   exit unless args.from_organization_id.present? and args.to_organization_id.present?
  #   total_changed = 0
  #   total_checked = 0
  # 
  #   all_cards = CardTemplate.where('organization_id >= ?', args.from_organization_id).where('organization_id <= ?', args.to_organization_id).order(organization_id: :asc)
  #   all_cards.each do |c|
  #     is_on_last = false
  #     total = c.template_fields.count
  #     placeholder_index = 0
  #     count = 0
  #     new_template_fields = []
  #     c.template_fields.each do |tf|
  #       count += 1
  #       
  #       if tf["type"].eql?"image"
  #         new_template_fields << tf
  #         total -= 1
  #         next
  #       end
  #       
  #       # unless tf["token"].blank?
  #       unless tf["token"].eql?"placeholder"
  #         new_template_fields << tf
  #       else
  #         placeholder_index = count
  #       end
  #     end
  #     
  #     if placeholder_index.eql?total and total > 0
  #       puts "Organization (ID:#{c.organization_id}) #{c.organization.name} - Template ID: #{c.id} - Name: #{c.name}"
  #       total_changed += 1
  #       c.template_fields = new_template_fields
  #       c.save!
  #     end
  #     
  #     total_checked += 1
  #   end
  # 
  #   puts "Total changed: #{total_changed}"
  #   puts "Total: #{total_checked}"
  # end

  # desc "Fix shipping cost range, for USPS"
  # task :fix_shipping_cost_range, [:from_organization_id, :to_organization_id] => :environment do |t, args|
  #   exit unless args.from_organization_id.present? and args.to_organization_id.present?
  #   total_fixed = 0
  #   total_deleted = 0
  #   total_checked = 0
  # 
  #   all_orgs = Organization.unscoped.where('id >= ?', args.from_organization_id).where('id <= ?', args.to_organization_id).order(:id => :asc)
  #   all_orgs.each do |org|
  #     all_costs = org.costs.where(costable_type: 'ShippingProvider').where(costable_id: 1).order(range_low: :asc)
  #     to_delete = all_costs.blank? ? false : true
  #     to_fix = false
  #     all_costs.each do |c|
  #       unless c.transaction_items.blank?
  #         to_delete = false
  #       end
  #       
  #       if c.range_low.eql?0 and c.range_high.eql?1 and c.value.to_s.eql?"0.49"
  #         to_fix = true
  #       end
  #     end
  #     
  #     if to_delete
  #       puts "Shipping cost being delete: #{org.name} (ID: #{org.id})"
  #       org.costs.where(costable_type: 'ShippingProvider').where(costable_id: 1).delete_all
  #       total_deleted += 1
  #     elsif to_fix
  #       puts "Shipping cost being fixed: #{org.name} (ID: #{org.id})"
  #       cost0 = all_costs[0]
  #       cost0.range_high = 3
  #       cost1 = all_costs[1]
  #       cost1.range_low = 4
  #       cost1.range_high = 9
  #       cost2 = all_costs[2]
  #       cost2.range_low = 10
  #       cost2.range_high = 19
  #       cost3 = all_costs[3]
  #       cost3.range_low = 20
  #       cost3.range_high = 29
  #       cost4 = all_costs[4]
  #       cost4.range_low = 30
  #       cost4.range_high = 49
  #       cost5 = all_costs[5]
  #       cost5.range_low = 50
  #       cost5.range_high = 99
  #       cost6 = all_costs[6]
  #       cost6.range_low = 100
  #       cost6.range_high = 100
  #       cost6.save!
  #       cost5.save!
  #       cost4.save!
  #       cost3.save!
  #       cost2.save!
  #       cost1.save!
  #       cost0.save!
  #       total_fixed += 1
  #     end
  #     
  #     total_checked += 1
  #   end
  # 
  #   puts "Total deleted: #{total_deleted}"
  #   puts "Total fixed: #{total_fixed}"
  #   puts "Total checked: #{total_checked}"
  # end

  desc "Fix Card Template reference on User Data model"
  task :look_fix_fieldsel_fields, [:from_organization_id, :to_organization_id] => :environment do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    total_to_fix = 0

    all_cards = CardTemplate.where('organization_id >= ?', args.from_organization_id).where('organization_id <= ?', args.to_organization_id).order(organization_id: :asc)
    all_cards.each do |c|
      to_fix = false
      next if c.id > 9999
      
      c.template_fields.each do |tf|
        next unless tf["type"].eql?"selectbox"
        unless tf["options"].blank?
          puts "Organization (ID:#{c.organization_id}) #{c.organization.name} - Template ID: #{c.id} - Name: #{c.name} should have fieldsel fixed."
          next
        end
        to_fix = true
      end
      
      if to_fix
        total_to_fix += 1
        puts "Organization (ID:#{c.organization_id}) #{c.organization.name} - Template ID: #{c.id} - Name: #{c.name} has a broken select box"
        legacy_card = Legacy::CardData.where("CARD_REF_NUM = ? and COMPANY_NO = ?", c.id, c.organization_id).first
        self.migrate_card(legacy_card, nil) unless legacy_card.blank?
      end
    end
    
    puts "Total to be fixed: #{total_to_fix}"
  end
  
  desc "Import new financial transactions"
  task :import_new_financial_transactions, [:organization_id, :last_trans_id] => :environment do |t, args|
    exit unless args.organization_id.present? and args.last_trans_id.present?
    
    credit_by_check = FinancialTransactionSubType.find(1)
    credit_by_cc = FinancialTransactionSubType.find(2)
    credit_by_refund = FinancialTransactionSubType.find(3)
    debit_by_print_card = FinancialTransactionSubType.find(4)
    debit_by_other = FinancialTransactionSubType.find(5)
    comment_author = User.where(email: "admin@instantcard.net").first
    comment_author ||= User.where(email: "system@instantcard.net").first

    org = Organization.find(args.organization_id)
    
    all_transactions = Legacy::Transaction.where("COMPANY_NO = ? and TRAN_NO > ?", args.organization_id, args.last_trans_id).order("COMPANY_NO, TRAN_NO")
    all_transactions.each do |transaction|
      new_ft = org.financial_transactions.where(:id => transaction.TRAN_NO).first_or_initialize
      new_ft_comment = "Migrated at #{Time.now}\n"

      case transaction.TRAN_TYPE
      when 0
        new_ft.financial_transaction_sub_type = (transaction.JOB_NUMBER.present? ? debit_by_print_card : debit_by_other)
        new_ft.debit = transaction.DEBIT.present? ? transaction.DEBIT : 0
        new_ft_comment << "JOB NUMBER: #{transaction.JOB_NUMBER}\n" if transaction.JOB_NUMBER.present?
        new_ft_comment << "CARD COST: #{transaction.CARD_COST}\n" if transaction.CARD_COST.present?
        new_ft_comment << "SHIPPING COST: #{transaction.SHIPPING_COST}\n" if transaction.SHIPPING_COST.present?
        new_ft.Debit!
      when 1
        new_ft.financial_transaction_sub_type = credit_by_refund
        new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
        new_ft.Credit!
      when 2
        new_ft.financial_transaction_sub_type = credit_by_check
        new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
        new_ft.Credit!
      when 3
        new_ft.financial_transaction_sub_type = credit_by_cc
        new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
        new_ft.Credit!
      else
        if transaction.CREDIT.present?
          new_ft.financial_transaction_sub_type = credit_by_check
          new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
          new_ft.Credit!
        elsif transaction.DEBIT.present?
          new_ft.financial_transaction_sub_type = (transaction.JOB_NUMBER.present? ? debit_by_print_card : debit_by_other)
          new_ft.debit = transaction.DEBIT.present? ? transaction.DEBIT : 0
          new_ft_comment << "JOB NUMBER: #{transaction.JOB_NUMBER}\n" if transaction.JOB_NUMBER.present?
          new_ft_comment << "CARD COST: #{transaction.CARD_COST}\n" if transaction.CARD_COST.present?
          new_ft_comment << "SHIPPING COST: #{transaction.SHIPPING_COST}\n" if transaction.SHIPPING_COST.present?
          new_ft.Debit!
        else
          # In this case it will be ignored and listed as warning
          MigrationTask.log_error_message(migration_task, org, "Transaction of unknown type (Type: #{transaction.TRAN_TYPE}) (ID: #{transaction.TRAN_NO}) (Date: #{transaction.TRAN_DATE}) being ignored.", :migration_log_warning)
          new_ft.delete
          org.migration_status_cd = [org.migration_status_cd.to_i, 1] # 1 is for :migration_log_warning
          org.save!
          next
        end
      end

      # Transactions will re-construct the balance with no need for the skip callback for now
      # new_ft.skip_callbacks = true
      new_ft.balance = transaction.BALANCE
      new_ft.created_at = transaction.TRAN_DATE.utc + 4.hours
      new_ft.updated_at = transaction.TRAN_DATE.utc + 4.hours
      new_ft.description = "#{transaction.CHEQUE_NO}" # if transaction.CHEQUE_NO.present?
      
      begin
        new_ft.save!

        # create comment:
        comment = ActiveAdmin::Comment.new(
          resource_id: new_ft.id,
          resource_type: new_ft.class.to_s,
          namespace: 'admin',
          author_id: comment_author.id,
          author_type: comment_author.class.to_s,
          body: new_ft_comment
        ).save!
      rescue Exception => e
        MigrationTask.log_error_message(migration_task, org, "Exception saving transaction (TRAN_NO: #{transaction.TRAN_NO}). Error: #{e.message}", :migration_log_error)
        log_level = set_log_level(log_level, :migration_log_error)
      end

    end

  end

  desc "Set Organization_ID on Print Jobs"
  task :set_organization_id_on_print_jobs => :environment  do |t, args|
    all_jobs = PrintJob.order(id: :asc)
    all_jobs.each do |pj|
      correct_org = pj.card_template.organization
      if pj.context["email"].present? and pj.card_template.organization_id < 20000000
        user = User.where(email: pj.context["email"].downcase).first
        if user.nil?
          puts "[WARNING] Print job for an unknown user: #{pj.context['email']}"
        elsif user.organization.nil?
          puts "[WARNING] Print job for an user (ID:#{user.id}/Email:#{pj.context['email']}) without organization"
        else
          correct_org = user.organization
          unless correct_org.id.eql?pj.card_template.organization.id
            puts "[INFO] Fixing print job (ID:#{pj.id}). Changing from #{pj.card_template.organization.id} to #{correct_org.id}"
          end
        end
      end
      
      pj.organization_id = correct_org.id
      pj.save!
      
      if pj.financial_transaction.present? and !pj.financial_transaction.organization_id.eql?correct_org.id
        puts "[FIXING-FIN] Print Job (ID:#{pj.id})"
        ft = pj.financial_transaction
        ft.organization_id = correct_org.id
        ft.save!
      end
    end
  end

  desc "Fix ABB financial transactions: ABB Prox card cost"
  task :fix_abb_financial_transactions => :environment do
    correct_cost_item = Cost.find(129)
    abb = Organization.find(660000)
    corgs = abb.child_organizations
    corgs.each do |corg|
      corg.financial_transactions.each do |ft|
        next if ft.id < 201522
        next unless ft.financial_transaction_sub_type_id.eql? 4
        next if ft.transaction_items.empty?
        ft.transaction_items.each do |ti|
          if ti.value.eql?(correct_cost_item.value*ti.total)
            # The value is the same
            if ti.cost.nil?
              # And it is pointing to a wrong cost Item
              # In this case don't need to update organization balance
              puts "[COST_ITEM] Fixing cost item for Financial Transaction Item ID #{ti.id}"
              ti.cost = correct_cost_item
              ti.save!
            end
          elsif ti.cost_id.eql?correct_cost_item.id and !ti.value.eql?(correct_cost_item.value*ti.total)
            # The cost is zero and points to the correct which has different value
            puts "[TI_VALUE] Fixing cost item value and Organization balence base on Financial Transaction Item ID #{ti.id}"
            ti.value = correct_cost_item.value * ti.total
            ti.save!
            ft.debit = ft.debit + ti.value
            ft.balance = ft.balance - ti.value
            ft.save
            abb.balance = abb.balance - ti.value
            abb.save!
          end
          ti
        end
      end
    end
  end

  desc "Fix ABB financial transactions: Shipping Provider cost item"
  task :fix_abb_financial_transactions_shipping_provider => :environment do

    default_usps_1 = Cost.find(1)
    default_usps_2 = Cost.find(63)
    default_usps_3 = Cost.find(33668)
    default_usps_4 = Cost.find(64)
    default_usps_5 = Cost.find(65)
    default_usps_6 = Cost.find(66)
    default_usps_7 = Cost.find(66)
    default_usps = [default_usps_1, default_usps_2, default_usps_3, default_usps_4, default_usps_5, default_usps_6, default_usps_7]
    
    abb = Organization.find(660000)
    corgs = abb.child_organizations
    corgs.each do |corg|
      corg.financial_transactions.each do |ft|
        ft.transaction_items.each do |ti|
          next if ti.cost.present?
          updated = false
          default_usps.each do |dusps|
            if ti.total.eql?1 and ti.value.eql?dusps.value
              ti.cost = dusps
              ti.save!
              puts "Fixing TI (ID:#{ti.id}) with USPS cost (ID:#{dusps.id}) of value #{dusps.value.to_s}"
              updated = true
            end
          end
        end
      end
      
    end
    
  end
  
  desc "Search for templates with Remove Color Filter"
  task :search_templates_with_remove_color_filter => :environment do
    # Order by Card Template
    # CardTemplate.order(id: :asc).all.each do |template|
    #   if template.front_data.match(/\"RemoveWhite\"/) or template.back_data.match(/\"RemoveWhite\"/)
    #     puts "Card template '#{template.name}' (ID:#{template.id}) from organization '#{template.organization.name}' (ID:#{template.organization.id}) uses RemoveWhite filter"
    #   end
    # end
    
    # Order by Organization
    # Organization.order(id: :asc).all.each do |org|
    Organization.unscoped.org_is_active.order(last_financial_transaction: :desc).all.each do |org|
      org.card_templates.order(id: :asc).all.each do |template|
        if template.front_data.match(/\"RemoveWhite\"/) or template.back_data.match(/\"RemoveWhite\"/)
          # puts "Card template '#{template.name}' (ID:#{template.id}) from organization '#{template.organization.name}' (ID:#{template.organization.id}) uses RemoveWhite filter"
          puts "Organization '#{template.organization.name}' (ID:#{template.organization.id}), card template '#{template.name}' (ID:#{template.id}) uses RemoveWhite filter"
        end
      end
    end
  end

  desc "Search for templates with Remove Color Filter"
  task :search_for_duplicate_contact_and_address => :environment do
    total_orgs = 0
    Organization.all.each do |org|
      org_conts_deleted = []
      org_addrs_deleted = []

      if org.addresses.count > 1
        org.addresses.each do |addr1|
          next if org_addrs_deleted.include?addr1.id
          org.addresses.each do |addr2|
            next if addr1.id.eql?addr2.id
            next if org_addrs_deleted.include?addr2.id
            if addr1.address1.downcase.eql?addr2.address1.downcase
              # one to be deleted
              if addr1.id < addr2.id and addr1.primary
                # Delete the higher ID, if the smaller is the primary
                if addr2.contact.present?
                  # Also delete the contact if present
                  puts "[DUP_CON_ADDR] Organization '#{org.name}' (ID:#{org.id}): deleting contact (ID:#{addr2.contact.id})" # "(#{addr2.contact.attributes.to_s})"
                  org_conts_deleted.push(addr2.contact.id)
                  addr2.contact.delete
                end
                puts "[DUP_CON_ADDR] Organization '#{org.name}' (ID:#{org.id}): deleting addr (ID:#{addr2.id})" # "(#{addr2.attributes.to_s})"
                org_addrs_deleted.push(addr2.id)
                addr2.delete
                total_orgs += 1
              else
                if addr1.contact.present?
                  # Also delete the contact if present
                  puts "[DUP_CON_ADDR] Organization '#{org.name}' (ID:#{org.id}): deleting contact (ID:#{addr1.contact.id})" # "(#{addr1.contact.attributes.to_s})"
                  org_conts_deleted.push(addr1.contact.id)
                  addr1.contact.delete
                end
                puts "[DUP_CON_ADDR] Organization '#{org.name}' (ID:#{org.id}): deleting addr (ID:#{addr1.id})" # "(#{addr1.attributes.to_s})"
                total_orgs += 1
                addr1.delete
              end
            end
          end
        end
      end
      
      if org.contacts.count > 1
        org.contacts.each do |cont1|
          next if org_conts_deleted.include?cont1.id
          org.contacts.each do |cont2|
            next if cont1.id.eql?cont2.id
            next if org_conts_deleted.include?cont2.id
            if cont1.id < cont2.id
              puts "[DUP_CONT1_ADDR] Organization '#{org.name}' (ID:#{org.id}): deleting contact (ID:#{cont2.id})" # "(#{cont2.attributes.to_s})"
              org_conts_deleted.push(cont2.id)
              cont2.delete
            else
              puts "[DUP_CONT2_ADDR] Organization '#{org.name}' (ID:#{org.id}): deleting contact (ID:#{cont1.id})" # "(#{cont1.attributes.to_s})"
              org_conts_deleted.push(cont1.id)
              cont1.delete
            end
            
            total_orgs += 1 if org_addrs_deleted.empty?
          end
        end
      end
    end
    
    puts "Total of Orgs cleaned: #{total_orgs}"

    Organization.all.each do |org|
      primary_poc = org.addresses.where(primary: true)
      unless primary_poc.present?
        puts "[DUP_CON_ADDR] Organization '#{org.name}' (ID:#{org.id}) doesn't have a primary address"
      end
    end
  end


  desc "Import new financial transactions"
  task :clean_default_shipping_cost, [:from_organization_id, :to_organization_id] => :environment do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?

    total_orgs = 0
    total_orgs_to_be_updated = 0
    all_shipping_providers = ShippingProvider.all
    all_orgs = Organization.where("id >= ? and id <= ?", args.from_organization_id, args.to_organization_id)
    all_orgs.each do |org|
      message = ""
      cleaned_org = false
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

           # Delete this org based shipping cost or replace to a default item
           no_trans = true
           org_cost_sp.each do |cost_item|
             no_trans = false unless cost_item.transaction_items.empty?
           end
           if no_trans
             # Delete
             puts "[CLEAN_SHIPPING_COST] Organization '#{org.name}' (ID:#{org.id}): deleting custom cost for '#{sp.name}' (ID:#{sp.id})"
             org_cost_sp.delete_all
           end
           cleaned_org = true
         end
      end

      if cleaned_org
        total_orgs += 1
      end
    end
    
    puts "Total organizations cleaned: #{total_orgs}"
  end

  task :fix_all_financial_transactions_shipping_provider, [:from_organization_id, :to_organization_id] => :environment do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?

    default_usps_1 = Cost.find(1)
    default_usps_2 = Cost.find(63)
    default_usps_3 = Cost.find(33668)
    default_usps_4 = Cost.find(64)
    default_usps_5 = Cost.find(65)
    default_usps_6 = Cost.find(66)
    default_usps_7 = Cost.find(66)
    default_fedex_overnight = Cost.find(68)
    default_ups_overnight = Cost.find(69)
    default_usps = [default_usps_1, default_usps_2, default_usps_3, default_usps_4, default_usps_5, default_usps_6, default_usps_7, default_fedex_overnight, default_ups_overnight]
    
    all_orgs = Organization.where("id >= ? and id <= ?", args.from_organization_id, args.to_organization_id)
    all_orgs.each do |org|
      org.financial_transactions.each do |ft|
        ft.transaction_items.each do |ti|
          next unless ti.cost.present?
          next unless ti.cost.organization.present?
          next unless ti.cost.costable_type.match(/ShippingProvider/)

          updated = false
          default_usps.each do |dusps|
            if ti.cost.costable_id.eql?dusps.costable_id and ti.value.eql?dusps.value #and ti
              puts "[UPDATE_TI_SHIPPING_COST] Fixing FT (ID:#{ft.id}) TI (ID:#{ti.id}) (#{ti.cost.id}) with '#{dusps.costable.name}' cost (ID:#{dusps.id}) of value #{dusps.value.to_s}"
              ti.cost = dusps
              ti.save!
              updated = true
            end
          end
          
          unless updated
            puts "[UPDATE_TI_SHIPPING_COST] Couldn't find equivalent for TI (ID:#{ti.id}) on FT ID #{ft.id}"
          end
        end
      end
      
    end
    
  end

  desc "Fail duplicated Print Jobs"
  task :fail_duplicated_print_jobs, [:organization_id, :do_it] => :environment  do |t, args|
    exit unless args.organization_id.present? and args.do_it.present?
    
    bool_do_it = args.do_it.eql?"true"
    
    scheduled_jobs = PrintJob.where(status_cd: 1).where(organization_id: args.organization_id)
    scheduled_jobs.each do |job|
      job = PrintJob.find(job.id)
      next unless job.Scheduled?
      user_data_1 = ""
      begin
        user_data_1 = job.list_users.first.user_datum.first.data["DATA_1"]
      rescue
        puts "Job #{job.id} don't have list of users or user data. Will remain scheduled"
        next
      end

      cards_printed = UserDatum.where(card_template_id: job.card_template_id).where(status_cd: 1).ransack(DATA_1_eq: user_data_1).result
      if cards_printed.count > 0
        puts "Job #{job.id} has a duplicated & printed card. Data_1: #{user_data_1}"
        if bool_do_it
          job.Failed!
          job.printed_at = Time.now
          job.save!
        end
        next
      end
      
      cards = UserDatum.where(card_template_id: job.card_template_id).ransack(DATA_1_eq: user_data_1).result
      
      cards.each do |card|
        next unless card.list_user_id.present?
        next if card.list_user.print_job.Created? or card.list_user.print_job.Failed? or card.list_user.print_job.No_Balance?
        next if job.id.eql? card.list_user.print_job.id
        
        if card.list_user.print_job.Scheduled?
          # It is also scheduled and duplicated
          puts "Job #{job.id} has a duplicated scheduled job (ID: #{card.list_user.print_job.id}) card. Data_1: #{user_data_1}"
          if bool_do_it
            card.list_user.print_job.Failed!
            card.list_user.print_job.save!
          end
          next
        end
        
      end

    end
  end

  desc "Import organizations"
  task :import_organizations, [:file_path] => :environment do |t, args|
    import_file_path = args.file_path.present? ? args.file_path : "#{Rails.root.to_s}/tmp/csv/batch_organization_import.csv"
    export_file_path = "#{Rails.root.to_s}/tmp/csv/batch_organization_export.csv"
    line_number = 0

    if File.file?(import_file_path)
      CSV.open(export_file_path, "wb") do |csv|
        CSV.foreach(import_file_path) do |row|
          line_number += 1
          next if row[0].present? && row[0].start_with?('--', '=', '#')

          begin
            [2, 6, 7, 13, 15, 16, 17, 18, 19, 20].each do |i|
              unless row[i].present?
                raise "Required fields missing at line #{line_number}"
              end
            end

            # Check if we need to update existing organization or create a new one
            if row[0].present?
              organization = Organization.find_by_id(row[0])
              unless organization.present?
                raise 'Unknown organization'
              end
            else
              organization = Organization.find_by_name(row[2].strip)
              unless organization.present?
                # One last try to find Org, based on user email
                user = User.where('LOWER(email) = :email', email: row[19].strip.downcase).first
                organization = user.organization if user.present?
              end
              organization ||= Organization.new
            end

            organization.NewSystem!
            organization.name = row[2].strip
            organization.overdraft = row[5].to_f if row[5].present?

            # Check if parent organization exists
            if row[1].present?
              parent_organization = Organization.find_by_id(row[1])
              unless parent_organization.present?
                raise 'Unknown parent organization'
              end

              organization.parent_organization_id = parent_organization.id
            end

            # Get and set industry id
            if row[3].present?
              industry = Industry.where('LOWER(name) = ?', row[3].strip.downcase).first
              unless industry.present?
                raise 'Unknown industry'
              end

              organization.industry_id = industry.id
            end

            # Get and set category id
            if row[4].present?
              category = Category.where('LOWER(name) = ?', row[4].strip.downcase).first
              unless category.present?
                raise 'Unknown category'
              end

              organization.category_id = category.id
            end

            Organization.transaction do
              unless organization.save
                ActiveRecord::Rollback
                raise organization.errors.full_messages.join(' | ')
              end

              # Check if we need to update existing contact or create a new one
              contact = Contact.where('organization_id = :organization_id AND LOWER(email) = :email', organization_id: organization.id, email: row[7].strip.downcase).first

              unless contact.present?
                contact = Contact.new(organization_id: organization.id)
              end

              contact.full_name = row[6].strip
              contact.email = row[7].strip.downcase
              contact.alt_email = row[8].strip if row[8].present?
              contact.phone_number = row[9].strip if row[9].present?
              contact.alt_phone_number = row[10].strip if row[10].present?
              contact.fax_number = row[11].strip if row[11].present?

              unless contact.save
                ActiveRecord::Rollback
                raise contact.errors.full_messages.join(' | ')
              end

              # Check if we need to update existing address or create a new one
              address = Address.where('organization_id = :organization_id AND LOWER(TRIM(address1)) = :address1', organization_id: organization.id, address1: row[13].strip.downcase).first

              unless address.present?
                address = Address.new(organization_id: organization.id)
              end

              address.organization_name = organization.name
              address.label = row[12].strip if row[12].present?
              address.primary = true
              address.address1 = row[13].strip
              address.address2 = row[14].strip.downcase if row[14].present?
              address.city = row[15].strip
              address.state = row[16].strip
              address.zip_code = row[17].strip
              address.country = row[18].strip
              address.contact = contact

              unless address.save
                ActiveRecord::Rollback
                raise address.errors.full_messages.join(' | ')
              end

              # Unset 'primary' boolean from another address if needed
              if row[12].present? && row[12].strip.downcase == 'true'
                old_primary_address = Address.where('organization_id = :organization_id AND "primary" = true AND id != :id', organization_id: organization.id, id: address.id).first

                if old_primary_address.present?
                  old_primary_address.primary = false
                  old_primary_address.save
                end
              end

              # Check if we need to update existing user or create a new one
              user = User.where('organization_id = :organization_id AND LOWER(email) = :email', organization_id: organization.id, email: row[19].strip.downcase).first

              unless user.present?
                user = User.new(
                  organization_id: organization.id,
                  email: row[19].strip.downcase,
                  password: [*('a'..'z')].sample(8).join
                )

                user.add_role(:admin)
              end

              user.pin = row[20]

              unless user.save
                ActiveRecord::Rollback
                raise user.errors.full_messages.join(' | ')
              end

              if row[21].present?
                card_template = CardTemplate.find_by_id(row[21].strip)

                unless card_template.present?
                  raise 'Unknown card template id'
                end

                unless Organization.organizations_tree(card_template, false).collect { |obj| obj.id }.include?(organization.id)
                  raise 'Organization has to be in the organization tree to connect to card template'
                end

                shared_template = SharedTemplate.new(
                  organization_id: organization.id,
                  card_template_id: row[21].strip
                )

                # If there is already existing connection it will go ahead
                shared_template.save
              end

              row.delete(22)
              row[0] = organization.id
              csv << row
            end
          rescue Exception => e
            row[22] = e.message
            error_message = "Issue with line ##{line_number}: #{e.message}"
            puts error_message
            Rails.logger.info(error_message)
            csv << row
            next
          end
        end
      end
      puts 'Done! Output file path is "' + export_file_path + '"'
    else
      puts 'Import file not found!'
    end
  end

  desc "Clean un-used List Users"
  task :clean_list_users => :environment do
    ListUser.find_each(batch_size: 5000).each do |lu|
      if lu.print_job.nil?
        lu.destroy
      end
    end
  end

  desc "Replace font family"
  task :replace_font_family, [:old_font, :new_font] => :environment do |t, args|
    exit unless args.old_font.present? and args.new_font.present?
    total_changed = 0
    total = 0
    
    string_old_font = "\"fontFamily\":\"#{args.old_font}\""
    string_new_font = "\"fontFamily\":\"#{args.new_font}\""

    CardTemplate.find_each(batch_size: 1000).each do |c|
      front_changed = false
      back_changed = false
      
      if c.front_data.include?string_old_font
        puts "[1] Changing FrontData Template (ID:#{c.id}/Name:#{c.name})"
        front_changed = true
        c.front_data = c.front_data.gsub(string_old_font, string_new_font)
      else
        if c.used_fonts("front", true).include?args.old_font
          puts "[1.1] Changing FrontData Template (ID:#{c.id}/Name:#{c.name})"
          front_changed = true
          c.front_data = c.front_data.gsub(string_old_font, string_new_font)
        end
      end
      
      if c.back_data.include?string_old_font
        puts "[2] Changing BackData Template (ID:#{c.id}/Name:#{c.name})"
        back_changed = true
        c.back_data = c.back_data.gsub(string_old_font, string_new_font)
      else
        if c.used_fonts("back", true).include?args.old_font
          puts "[1.1] Changing BackData Template (ID:#{c.id}/Name:#{c.name})"
          front_changed = true
          c.back_data = c.back_data.gsub(string_old_font, string_new_font)
        end
      end
  
      if front_changed || back_changed
        c.save!
        total_changed += 1
      end
      
      total += 1
    end
    
    puts "Total changed: #{total_changed}"
    puts "Total: #{total}"
  end

  desc "Fix DK12 failed print jobs"
  task :fix_dk12_failed_print_jobs => :environment do
    total = 0
    total_fixed = 0
    PrintJob.where(organization_id: 2183000).where(status_cd: 4).each do |pj|
      if pj.printed_at.nil?
        pj.printed_at = pj.updated_at
        pj.save!
        total_fixed += 1
      end
      total += 1
    end
    
    puts "Total of jobs fixed: #{total_fixed}"
    puts "Total of jobs: #{total}"
  end
  
  desc "Investigate templates with QR Codes"
  task :investigate_template_with_qr_codes, [:card_template_id_file_path] => :environment do |t, args|
    exit unless args.card_template_id_file_path.present?

    CSV.foreach(args.card_template_id_file_path) do |card_template_id|
      begin
        c = CardTemplate.find(card_template_id.first)
        c.card_data.each do |cd|
          qr_code_obj = c.get_hash_object(cd["data"], "qrcode", "")
          unless qr_code_obj.nil?
            puts "Investigate template ID #{c.id}, organization #{c.organization.name} (ID:#{c.organization.id})"
          end
        end
      rescue Exception => e
      end
    end

  end

  desc "Validate relationship between card type and organization"
  task :validate_card_type_organization_relationship => :environment do
    global_types = ['white pvc', 'white pvc with magstripe', 'white pvc with globe hologram', 'pvc clear', 'pvc frosted']
    card_types = CardType.where('LOWER(name) NOT IN (?)', global_types)
    connections = []
    card_types.each do |card_type|
      organization_ids = []
      card_type.card_templates.each do |card_template|
        organizations_tree = Organization.organizations_tree(card_template)
        
        unless organizations_tree.empty?
          count = organizations_tree.length
          organizations_tree.each_with_index do |org, i|
            break if organization_ids.include?(org.id)
            if i + 1 == count
              organization_ids << card_template.organization.id
            end
          end
        else
          organization_ids << card_template.organization.id
        end
      end
      connections << {card_type.id => organization_ids}
    end

    puts connections.to_json
    connections.each do |conn|
      conn.each do |k,v|
        card_type = CardType.find(k.to_s.to_i)
        org_names = ""
        v.each do |org_id|
          org = Organization.where(id: org_id).first
          if org.present?
            org_names += " - #{org.name}"
          end
        end
        
        puts "Card Type #{card_type.name} (ID: #{card_type.id}) belong to: #{org_names}"
      end
    end
  end

  def add_special_handling_to_card_template_rec(org, sh)
    org.card_templates.each do |ct|
      ctsh = ct.special_handlings.where(id: sh.id)
      if ctsh.empty?
        puts "Adding #{sh.name} to #{ct.name}"
        ct.special_handlings.push(sh)
      end
    end

    org.child_organizations.each do |corg|
      add_special_handling_to_card_template_rec(corg, sh)
    end
  end

  desc "Investigate templates with QR Codes"
  task :add_special_handling_to_card_template, [:organization_id, :special_handling_id] => :environment do |t, args|
    exit unless args.organization_id.present? and args.special_handling_id.present?
    
    org = Organization.find(args.organization_id)
    sh = SpecialHandling.find(args.special_handling_id)
    exit unless org.present? or sh.present?
    
    add_special_handling_to_card_template_rec(org, sh)    
  end

end
