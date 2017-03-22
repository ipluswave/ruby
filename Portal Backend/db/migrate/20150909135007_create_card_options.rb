class CreateCardOptions < ActiveRecord::Migration
  def change
    create_table :card_options do |t|
      t.string :element
      t.string :key
      t.string :value
      t.timestamps
    end
  end
end
