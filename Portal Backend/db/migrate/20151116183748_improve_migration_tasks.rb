class ImproveMigrationTasks < ActiveRecord::Migration
  def change
    add_column :migration_logs, :status_cd, :integer, :default => 0
    create_table :migration_tasks_organizations, id: false do |t|
      t.belongs_to :migration_task, index: true
      t.belongs_to :organization, index: true
    end
  end
end
