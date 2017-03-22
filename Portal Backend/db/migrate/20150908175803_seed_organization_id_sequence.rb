class SeedOrganizationIdSequence < ActiveRecord::Migration
  def migrate(direction)
    super
    
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE organizations_id_seq RESTART WITH 20000000") if direction == :up
  end

  def change
  end
end
