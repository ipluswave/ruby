class CreateAddress < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :label
      t.string :full_name
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :country
      t.belongs_to :organization
      t.timestamps null: false
    end
    remove_column :organizations, :address, :string
  end
end
