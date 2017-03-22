ActiveAdmin.register Site do
  permit_params :name
  menu parent: 'Print Locations', priority: 1

end
