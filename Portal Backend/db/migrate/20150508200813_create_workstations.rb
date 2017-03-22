class CreateWorkstations < ActiveRecord::Migration
  def change
    create_table :workstations do |t|
      t.string :name

      t.timestamps null: false
    end
    
    create_table :groups do |t|
      t.string :name
      t.references :workstation, index: true
      

      t.timestamps null: false
    end
    
    create_table :printers do |t|
      t.string :name
      t.references :card_type, index: true
      t.references :group, index: true

      t.timestamps null: false
    end
  end
end
