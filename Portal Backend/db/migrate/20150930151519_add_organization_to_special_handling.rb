class AddOrganizationToSpecialHandling < ActiveRecord::Migration
  def change
    add_column :special_handlings, :organization_id, :integer
  end
end
