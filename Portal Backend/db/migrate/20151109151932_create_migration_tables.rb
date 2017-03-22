class CreateMigrationTables < ActiveRecord::Migration
  def change
    create_table :migration_tasks do |t|
      t.integer :user_id
      t.integer :from_organization_id
      t.integer :to_organization_id
      t.integer :status_cd, :default => 0
      t.timestamps null: false
    end
    
    create_table :migration_logs do |t|
      t.references :migration_task, index: true
      t.references :organization, index: true
      t.text :message
      t.timestamps null: false
    end
  end
end
