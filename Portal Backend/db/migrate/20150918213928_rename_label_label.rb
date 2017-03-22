class RenameLabelLabel < ActiveRecord::Migration
  def change
    remove_column :label_templates, :label, :string, :default => ""
    add_column :label_templates, :type_cd, :integer, :default => 0
  end
end
