class CreateFonts < ActiveRecord::Migration
  def change
    create_table :fonts do |t|
      t.string :name
      t.string :url
      t.json :files, :default => []
      t.references :organization, :index => true

      t.timestamps
    end
  end
end
