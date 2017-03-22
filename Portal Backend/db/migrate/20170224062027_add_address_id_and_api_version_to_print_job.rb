class AddAddressIdAndApiVersionToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :address_id, :integer
    add_column :print_jobs, :api_version_cd, :integer, default: 0
    add_index :print_jobs, :address_id
  end
end
