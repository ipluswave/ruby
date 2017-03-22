class AddFaxToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :fax_number, :string
    remove_column :contacts, :last_name, :string
    rename_column :contacts, :first_name, :full_name

    add_index(:contacts, :email)
    add_index(:contacts, :full_name)
    add_index(:addresses, :address1)
    add_index(:addresses, :label)
    add_index(:addresses, :organization_name)
  end
end
