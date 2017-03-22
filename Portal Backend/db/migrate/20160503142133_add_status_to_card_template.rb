class AddStatusToCardTemplate < ActiveRecord::Migration
  def change
    add_column :card_templates, :status_cd, :integer, :default => 0
    
    CardTemplate.update_all(:status_cd => 1)
  end
end
