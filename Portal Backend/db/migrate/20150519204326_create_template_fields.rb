class CreateTemplateFields < ActiveRecord::Migration
  def change
    add_column :card_templates, :template_fields, :json, :default => []
  end
end
