class ChangeDefaultLetterPageSize < ActiveRecord::Migration
  def up
    change_column :letter_templates, :page_size, :string, :default => 'Letter'
  end
  
  def down
    change_column :letter_templates, :page_size, :string, :default => 'A4'
  end
end
