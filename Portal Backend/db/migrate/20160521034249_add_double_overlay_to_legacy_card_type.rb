class AddDoubleOverlayToLegacyCardType < ActiveRecord::Migration
  def change
    add_column :legacy_card_types, :double_overlay, :boolean, :default => false
  end
end
