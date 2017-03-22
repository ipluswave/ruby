class AddOptionsToLetter < ActiveRecord::Migration
  def change
    add_column :letter_templates, :margin_top, :integer, :default => 10
    add_column :letter_templates, :margin_bottom, :integer, :default => 10
    add_column :letter_templates, :margin_left, :integer, :default => 10
    add_column :letter_templates, :margin_right, :integer, :default => 10
    add_column :letter_templates, :page_size, :string, :default => 'A4'
    add_column :letter_templates, :orientation, :string, :default => 'Portrait'
  end
end
