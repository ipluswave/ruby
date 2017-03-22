class CreateCosts < ActiveRecord::Migration
  def change
    create_table :costs do |t|
      t.integer :value
      t.integer :quantity
      
      t.timestamps null: false
    end
  end
end
