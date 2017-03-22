class AddShippingProviderToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :shipping_provider_id, :integer, :default => 1
  end
end
