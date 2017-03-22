class AddAttributesToCardTemplate < ActiveRecord::Migration
  def change
    add_column :card_templates, :options, :json, :default => []
  end
end
