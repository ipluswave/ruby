class AddExtrasToUser < ActiveRecord::Migration
  def change
    add_column :users, :organization_id, :integer
    add_column :users, :pin, :string
  end
end
