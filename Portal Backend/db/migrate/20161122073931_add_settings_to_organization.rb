class AddSettingsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :settings, :json, :default => {}
  end
end
