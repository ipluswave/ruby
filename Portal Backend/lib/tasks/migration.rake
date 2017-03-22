namespace :migration do
  desc "Migrate Companies from the Legacy DB"
  task :companies, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
    mt.Running!
    mt.save!
    
    # Import all Organizations (and its parent)
    Legacy::Company.migrate(args.from_organization_id, args.to_organization_id, mt)
    
    mt.Finished!
    mt.save!
  end

  desc "Migrate Users from the Legacy DB"
  task :users, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
    mt.Running!
    mt.save!

    Legacy::Security.migrate(args.from_organization_id, args.to_organization_id, mt)

    mt.Finished!
    mt.save!
  end

  desc "Migrate Shipping Costs from the Legacy DB"
  task :shipping_costs, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
    mt.Running!
    mt.save!

    # Migrate Shipping cost
    Legacy::ShippingCost.migrate(args.from_organization_id, args.to_organization_id, mt)

    # Clean duplicated shipping cost
    Legacy::ShippingCost.clean_default(args.from_organization_id, args.to_organization_id, mt)

    mt.Finished!
    mt.save!
  end

  desc "Migrate Card Costs from the Legacy DB"
  task :card_costs, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
    mt.Running!
    mt.save!

    # Migrage Card cost
    Legacy::CardCost.migrate(args.from_organization_id, args.to_organization_id, mt)

    Legacy::CardCost.clean_default(args.from_organization_id, args.to_organization_id, mt)

    mt.Finished!
    mt.save!
  end

  desc "Migrate Financial Transactions from the Legacy DB"
  task :transactions, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
    mt.Running!
    mt.save!

    # Migrate transactions
    Legacy::Transaction.migrate(args.from_organization_id, args.to_organization_id, mt)

    mt.Finished!
    mt.save!
  end
  
  desc "Migrate Card Templates from the Legacy DB"
  task :card_templates, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    exit unless args.from_organization_id.present? and args.to_organization_id.present?
    mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
    mt.Running!
    mt.save!

    # Migrate transactions
    Legacy::CardData.migrate(args.from_organization_id, args.to_organization_id, mt)

    mt.Finished!
    mt.save!
  end
  
  desc "Migrate List of Card Templates from the Legacy DB"
  task :card_templates_from_org_list, [] => :environment do |t, args|
    mt = MigrationTask.new({:from_organization_id => 0, :to_organization_id => 0})
    mt.Running!
    mt.save!

    count = 0
    proc_file = File.new("#{Rails.root.to_s}/lib/tasks/organization_list_proc.txt", "w+")
    File.open("#{Rails.root.to_s}/lib/tasks/organization_list.txt").each do |org_id|
      next if org_id[0..1].eql? "--"
      org_id.chomp!
      next if org_id.empty?

      Legacy::CardData.migrate(org_id, org_id, mt)
      proc_file.puts "#{org_id}"
    end

    proc_file.close
    mt.Finished!
    mt.save!
  end
  
  desc "Migrate Card Types from CSV file"
  task card_types: :environment do
    File.open("#{Rails.root.to_s}/lib/tasks/card_types_to_csv_v2.txt").each do |line|
      next if line[0..1].eql? "--"
      card_type_name = line.split(",")[1].strip
      new_card_type = CardType.where(name: card_type_name).first_or_initialize
      new_card_type.description = "Migrated on #{Time.now}" unless new_card_type.description.present?
      new_card_type.save!
    end
    
    line_count = 0
    File.open("#{Rails.root.to_s}/lib/tasks/main_card_types_to_csv_v2.csv").each do |line|
      line_count += 1
      next if line_count.eql?1
      items = line.split(',')
      new_card_type_id = items[5]
      new_card_type = (new_card_type_id.present? ? CardType.find(new_card_type_id) : CardType.where(name: items[4]).first)
      legacy_card_type = LegacyCardType.where(legacy_card_type_id: items[0].to_i).first
      legacy_card_type ||= new_card_type.legacy_card_types.new
      legacy_card_type.update_attributes({
        legacy_card_type_id: items[0].to_i,
        name: items[1],
        mag_stripe: items[2],
        double_sided: items[3],
        cart_type_name: items[4],
        slot_punch: items[6],
        overlay: items[7],
        color_color: items[8],
        drop_ship: items[9],
        accessories: items[10],
        grommet: items[11],
        hole_punch: items[12].strip,
        double_overlay: items[13].strip
        })
      legacy_card_type.save!
    end
  end

  desc "Migrate Special Handlings from CSV file"
  task special_handlings: :environment do
    File.open("#{Rails.root.to_s}/lib/tasks/special_handlings_to_csv.txt").each do |line|
      next if line[0..1].eql? "--"
      new_spec_handling_name = line.split(",")[1].strip
      new_spec_handling = SpecialHandling.where(name: new_spec_handling_name).first_or_initialize
      new_spec_handling.description = "Migrated on #{Time.now}"
      new_spec_handling.save!
    end
  end
  
  desc "Backup a preview image from the Legacy system"
  task :backup_card_template_image, [:from_organization_id, :to_organization_id] => :environment do |t,args|
    Legacy::CardData.backup_card_template_image(args.from_organization_id, args.to_organization_id)
  end
  
  desc "Switch Companies range"
  task :switch_range, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    Organization.switch_range(args.from_organization_id, args.to_organization_id)
  end

  desc "Switch Companies with no templates"
  task :switch_no_templates, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    Organization.switch_no_templates(args.from_organization_id, args.to_organization_id)
  end

  desc "Switch Inactive Companies"
  task :switch_inactive, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    Organization.switch_inactive(args.from_organization_id, args.to_organization_id)
  end

  desc "Switch Companies with no templates"
  task :switch_migration_ok, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
    Organization.switch_migration_ok(args.from_organization_id, args.to_organization_id)
  end

  desc "Update approved card templates count for organizations"
  task :update_approved_card_template_count => :environment do |t, args|
    Organization.all.each do |organization|
      organization.update_attribute(:approved_card_template_count, organization.card_templates.where("status_cd = 1").count)
    end
  end

  namespace :default do
    desc "Clean shipping cost for companies that are equal to the Default one"
    task :clean_shipping_cost, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
      exit unless args.from_organization_id.present? and args.to_organization_id.present?
      mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
      mt.Running!
      mt.save!

      # Clean Shipping cost
      Legacy::ShippingCost.clean_default(args.from_organization_id, args.to_organization_id)

      mt.Finished!
      mt.save!
    end
  
    desc "Clean card cost for companies that are equal to the Default one"
    task :clean_card_cost, [:from_organization_id, :to_organization_id] => :environment  do |t, args|
      exit unless args.from_organization_id.present? and args.to_organization_id.present?
      mt = MigrationTask.new({:from_organization_id => args.from_organization_id, :to_organization_id => args.to_organization_id})
      mt.Running!
      mt.save!

      # Clean Card cost
      Legacy::CardCost.clean_default(args.from_organization_id, args.to_organization_id)

      mt.Finished!
      mt.save!
    end
  end

end
