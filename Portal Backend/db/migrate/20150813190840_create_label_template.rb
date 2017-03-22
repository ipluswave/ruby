class CreateLabelTemplate < ActiveRecord::Migration
  def change
    create_table :label_templates do |t|
      t.text :template
      t.references :organization
      t.timestamps
    end

    create_table :letter_templates do |t|
      t.text :template
      t.references :organization
      t.timestamps
    end
  end
end
