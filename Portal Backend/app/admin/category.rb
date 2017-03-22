ActiveAdmin.register Category do
  permit_params :name
  menu parent: 'Settings', priority: 11
  
  filter :name
  filter :created_at
  filter :updated_at
end
