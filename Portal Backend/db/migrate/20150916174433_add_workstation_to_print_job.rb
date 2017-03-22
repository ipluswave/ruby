class AddWorkstationToPrintJob < ActiveRecord::Migration
  def change
    change_table :print_jobs do |t|
      t.references :workstation
      t.integer :type_cd, :default => 0
      t.boolean :charge, :default => true
    end
    change_column :print_jobs, :status_message, :text, :default => ""
    
    change_table :user_data do |t|
      t.integer :status_cd, :default => 0
    end
  end
end
