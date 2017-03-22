class CreateContacts < ActiveRecord::Migration
  def change
    rename_column :addresses, :full_name, :organization_name
    add_column :addresses, :contact_id, :integer
    
    create_table :contacts do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :alt_email
      t.string :phone_number
      t.string :alt_phone_number
      t.references :organization, :index => true
      
      t.timestamps null: false
    end
  end
end
