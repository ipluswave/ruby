class CreateCardTypes < ActiveRecord::Migration
  def change
    create_table :card_types do |t|
      t.integer :type
      t.string :name
      t.text :description
      
      t.timestamps null: false
    end
  end
end
