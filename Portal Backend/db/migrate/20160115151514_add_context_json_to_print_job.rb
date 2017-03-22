class AddContextJsonToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :context, :json, :default => {}
    add_column :print_jobs, :number_of_copies, :integer, :default => 1
  end
end
