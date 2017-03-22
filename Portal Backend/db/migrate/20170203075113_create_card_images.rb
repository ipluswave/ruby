class CreateCardImages < ActiveRecord::Migration
  def change
    create_table :card_images do |t|
      t.string :file
      t.string :token
      t.references :imageable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
