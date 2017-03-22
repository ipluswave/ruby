class AddLabelToLabelTemplate < ActiveRecord::Migration
  def change
    add_column :label_templates, :label, :string, :default => ""
  end
end
