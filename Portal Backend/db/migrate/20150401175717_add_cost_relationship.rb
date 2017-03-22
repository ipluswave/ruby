class AddCostRelationship < ActiveRecord::Migration
  def change
    add_column :costs, :costable_id, :integer
    add_column :costs, :costable_type, :string
    add_reference :costs, :organization, index: true
  end
end
