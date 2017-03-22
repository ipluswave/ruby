ActiveAdmin.register Industry do
  permit_params :name
  menu parent: 'Settings', priority: 10

  filter :name
  filter :created_at
  filter :updated_at
end
