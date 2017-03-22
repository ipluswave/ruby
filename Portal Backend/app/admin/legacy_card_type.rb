ActiveAdmin.register LegacyCardType do
  menu parent: 'Settings', priority: 1
  permit_params :card_type_id

  config.sort_order = 'legacy_card_type_id_asc'
  config.per_page = 500
  
  index do
    selectable_column
    column :legacy_card_type_id
    column :name
    column :mag_stripe
    column :double_sided
    column 'New Card Type Name', :cart_type_name
    column 'New Card Type ID', :card_type_id
    column 'Belongs to Card Type', :card_type
    column :slot_punch
    column :overlay
    column :double_overlay
    column :color_color
    column :drop_ship
    column :accessories
    column :grommet
    column :hole_punch
    column :created_at
    column :updated_at

    actions
  end

end
