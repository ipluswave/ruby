class CreateFontFiles < ActiveRecord::Migration
  def change
    create_table :font_files do |t|
      t.references :fontfileable, polymorphic: true, index: true
      t.string :stretch
      t.string :style
      t.string :weight
      t.string :file
      
      t.timestamps null: false
    end
    
    remove_column :fonts, :organization_id, :integer
    add_column :fonts, :global, :boolean
    
    create_table :fonts_organizations, id: false do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :font, index: true
    end

  end
end
