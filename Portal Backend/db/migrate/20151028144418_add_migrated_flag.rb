class AddMigratedFlag < ActiveRecord::Migration
  def change
    add_column :organizations, :system_cd, :integer
  end
end
