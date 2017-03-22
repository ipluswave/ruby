class CreateIndustryAndCategory < ActiveRecord::Migration
  def change
    create_table :industries do |t|
      t.string :name
      t.timestamps null: false
    end
    
    create_table :categories do |t|
      t.string :name
      t.timestamps null: false
    end
    
    add_column :organizations, :industry_id, :integer
    add_column :organizations, :category_id, :integer
  end
end
