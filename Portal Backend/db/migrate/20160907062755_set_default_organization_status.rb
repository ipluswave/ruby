class SetDefaultOrganizationStatus < ActiveRecord::Migration
  def change
    change_column :organizations, :system_cd, :integer, :default => 1
  end
end
