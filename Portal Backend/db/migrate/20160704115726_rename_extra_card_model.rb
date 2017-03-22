class RenameExtraCardModel < ActiveRecord::Migration
  def change
      rename_table :extra_cards, :shared_templates
      add_column :shared_templates, :id, :primary_key
  end
end
