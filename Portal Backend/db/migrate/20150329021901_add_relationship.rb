class AddRelationship < ActiveRecord::Migration
  def change
    add_reference :card_templates, :organization, index: true
    add_reference :card_templates, :card_type, index: true
  end
end
