class AddPrintJob < ActiveRecord::Migration
  def change
    create_table :print_jobs do |t|
      t.references :card_template, index: true
      
      t.timestamps null: false
    end
  end
end
