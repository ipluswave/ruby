class AddFlagsToPrinter < ActiveRecord::Migration
  def change
    add_column :printers, :print_label, :boolean, :default => false
    add_column :printers, :print_letter, :boolean, :default => false
  end
end
