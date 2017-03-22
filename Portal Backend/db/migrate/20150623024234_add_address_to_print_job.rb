class AddAddressToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :address, :text, :default => ""
  end
end
