class AddStatusToWorkstation < ActiveRecord::Migration
  def change
      add_column :workstations, :status_cd, :integer, :default => 1
  end
end
