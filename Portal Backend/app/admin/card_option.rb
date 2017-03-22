ActiveAdmin.register CardOption do
  permit_params :element, :key, :value
  menu parent: 'Settings', priority: 2

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :element, :as => :select, :collection => CardOption.element_options
      input :key, :as => :select, :collection => CardOption.key_options
      input :value, :as => :select, :collection => CardOption.value_options
    end
    actions
  end

  filter :element, as: :select, collection: CardOption.element_options
  filter :key, as: :select, collection: CardOption.key_options
  filter :value, as: :select, collection: CardOption.value_options
  filter :created_at
  filter :updated_at
  
end
