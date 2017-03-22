class CreateLegacyCardType < ActiveRecord::Migration
  def change
    create_table :legacy_card_types do |t|
      t.integer :legacy_card_type_id
      t.string :name
      t.boolean :mag_stripe
      t.boolean :double_sided
      t.string :cart_type_name
      t.integer :card_type_id
      t.boolean :slot_punch
      t.boolean :overlay
      t.boolean :color_color
      t.boolean :drop_ship
      t.string :accessories
      t.boolean :grommet
      t.boolean :hole_punch
      
      t.timestamps null: false
    end
  end
end
