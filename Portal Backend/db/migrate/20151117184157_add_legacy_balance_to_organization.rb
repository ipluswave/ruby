class AddLegacyBalanceToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :legacy_balance, :money
  end
end
