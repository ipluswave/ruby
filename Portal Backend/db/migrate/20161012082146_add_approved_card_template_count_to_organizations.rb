class AddApprovedCardTemplateCountToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :approved_card_template_count, :integer, :default => 0
  end
end
