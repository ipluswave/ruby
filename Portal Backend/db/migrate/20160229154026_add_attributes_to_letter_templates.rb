class AddAttributesToLetterTemplates < ActiveRecord::Migration
  def change
    add_column :letter_templates, :font_id, :integer
    add_column :letter_templates, :font_size, :integer, :default => 10
    add_column :letter_templates, :line_height, :integer, :default => 15
  end
end
