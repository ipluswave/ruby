class AddToAddressToLabel < ActiveRecord::Migration
  def change
    add_column :label_templates, :to_address, :text, :default => ''
  end
end
