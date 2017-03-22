class CreateSpecialHandling < ActiveRecord::Migration
  def change
    create_table :special_handlings do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    
    create_table :card_templates_special_handlings, id: false do |t|
      t.belongs_to :card_template, index: true
      t.belongs_to :special_handling, index: true
    end
  end
end
