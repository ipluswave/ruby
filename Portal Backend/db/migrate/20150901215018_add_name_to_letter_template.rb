class AddNameToLetterTemplate < ActiveRecord::Migration
  def change
    add_column :letter_templates, :name, :string, :default => ""
  end
end
