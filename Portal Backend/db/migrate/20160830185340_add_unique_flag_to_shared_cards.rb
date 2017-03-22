class AddUniqueFlagToSharedCards < ActiveRecord::Migration
  def change
    add_column :shared_templates, :clone_card_template_id, :integer
    add_column :card_templates, :master_card_template_id, :integer
  end
end
