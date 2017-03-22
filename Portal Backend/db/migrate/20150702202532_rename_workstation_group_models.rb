class RenameWorkstationGroupModels < ActiveRecord::Migration
  def change
    rename_table :workstations, :sites
    rename_table :groups, :workstations
    rename_column :workstations, :workstation_id, :site_id
    rename_column :printers, :group_id, :workstation_id
  end
end
