class CreateCardTemplates < ActiveRecord::Migration
  def migrate(direction)
    super
    
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE card_templates_id_seq RESTART WITH 9999") if direction == :up
  end
  
  def change
    create_table :card_templates do |t|
      t.string :name
      
      t.timestamps null: false
    end
  end
end
