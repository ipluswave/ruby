class AddErrorMessageToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :status_message, :text
  end
end
