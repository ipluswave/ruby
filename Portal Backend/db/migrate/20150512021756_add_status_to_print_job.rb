class AddStatusToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :status_cd, :integer, :default => 0
  end
end
