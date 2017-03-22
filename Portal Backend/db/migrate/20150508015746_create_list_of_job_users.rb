class CreateListOfJobUsers < ActiveRecord::Migration
  def change
    create_table :list_users do |t|
      t.references :print_job, index: true
      t.timestamps
    end
    
    create_table :user_data do |t|
      t.references :list_user, index: true
      t.references :users, index: true
      t.json :data, :default => []
      t.timestamps
    end
  end
end
