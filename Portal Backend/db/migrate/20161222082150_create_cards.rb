class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.references :organization, index: true
      t.references :card_template, index: true
      t.json :data, :default => []

      t.timestamps null: false
    end
  end
end
