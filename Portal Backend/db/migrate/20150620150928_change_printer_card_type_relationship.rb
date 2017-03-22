class ChangePrinterCardTypeRelationship < ActiveRecord::Migration
  def change
    remove_column :printers, :card_type_id, :integer
    
    create_table :card_types_printers, id: false do |t|
      t.belongs_to :card_type, index: true
      t.belongs_to :printer, index: true
    end
  end
end
