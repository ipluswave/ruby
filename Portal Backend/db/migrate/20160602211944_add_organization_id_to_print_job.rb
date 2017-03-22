class AddOrganizationIdToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :organization_id, :integer
  end
end
