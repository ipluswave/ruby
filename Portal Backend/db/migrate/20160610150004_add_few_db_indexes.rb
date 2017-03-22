class AddFewDbIndexes < ActiveRecord::Migration
  def change
    add_index :organizations, :name
    add_index :card_templates, :name
    
    ActiveRecord::Base.connection.execute("CREATE INDEX ON user_data((data->>'DATA_1'));")# if direction == :up
    ActiveRecord::Base.connection.execute("CREATE INDEX ON user_data((data->>'DATA_2'));")# if direction == :up
    ActiveRecord::Base.connection.execute("CREATE INDEX ON user_data((data->>'DATA_3'));")# if direction == :up

  end
end
