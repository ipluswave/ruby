class CreateShippingProviders < ActiveRecord::Migration
  def change
    create_table :shipping_providers do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end



