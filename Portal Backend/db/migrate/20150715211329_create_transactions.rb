class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.belongs_to :organization
      t.belongs_to :user
      t.text :description
      t.integer :operation_cd
      t.integer :value
      t.timestamps null: false
    end
  end
end
