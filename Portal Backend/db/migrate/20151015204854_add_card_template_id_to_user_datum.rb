class AddCardTemplateIdToUserDatum < ActiveRecord::Migration
  def change
    add_column :user_data, :card_template_id, :integer
    add_index :user_data, :card_template_id
  end
end
