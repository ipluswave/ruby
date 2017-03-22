ActiveAdmin.register ShippingProvider do
  permit_params :name
  menu parent: 'Settings', priority: 6

  filter :name
  
end
