namespace :general do
  desc "List Companies without Card Template"
  task :list_companies_without_card_template => :environment  do |t, args|
    total_with_cards = 0
    total_without_cards = 0
    total_without_cards_without_user = 0

    puts "COMPANY_NO,COMPANY_NAME,COMP_PHONE,COMPANY_CONTACT,COMP_EMAIL"
    Legacy::Company.find_each(batch_size: 5000) do |c|
      cc = Legacy::CardData.where("COMPANY_NO = ?", c.COMPANY_NO)
      
      # Discard companies with cards
      unless cc.empty?
        total_with_cards += 1
        next 
      end

      buffer = "#{c.COMPANY_NO},#{c.COMPANY_NAME},#{c.COMP_PHONE},#{c.COMPANY_CONTACT},#{c.COMP_EMAIL}"

      # This org has a card template
      total_without_cards += 1
      
      puts buffer
    end
    
    puts "Total with Cards: #{total_with_cards}"
    puts "Total without Cards: #{total_without_cards}"
    puts "Total without Cards: #{total_without_cards}"
  end
  
end
