class AddTotalCardsAndSpecHandlingToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :total_cards, :integer, :default => 0
    add_column :print_jobs, :special_handlings, :string, :default => nil
    
    PrintJob.all.each do |pj|
      pj.total_cards = pj.total_cards_shortcut
      pj.special_handlings = pj.special_handlings_tokens_shortcut
      pj.save!
    end
  end
end
