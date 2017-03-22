class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.text :address
      
      t.string :legacy_id
      t.integer :balance

      t.timestamps null: false
    end
  end
end
