class AddPaperTypeToLetterTemplate < ActiveRecord::Migration
  def change
    add_column :letter_templates, :paper_type, :string, :default => "default"
    add_column :special_handlings, :token, :string, :default => ""
  end
end
