class CreateOrganizationsCardTypes < ActiveRecord::Migration
  def change
    create_table :organizations_card_types do |t|
      t.belongs_to :organization
      t.belongs_to :card_type
      t.timestamps
    end
  end
end
