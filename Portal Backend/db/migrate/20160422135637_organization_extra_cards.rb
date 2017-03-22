class OrganizationExtraCards < ActiveRecord::Migration
  def change
    create_table :extra_cards, id: false do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :card_template, index: true
    end
  end
end
