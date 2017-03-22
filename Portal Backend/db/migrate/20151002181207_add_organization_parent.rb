class AddOrganizationParent < ActiveRecord::Migration
  def change
    add_column :organizations, :parent_organization_id, :integer
  end
end
