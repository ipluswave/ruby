ActiveAdmin.register FontFile do
  permit_params :fontfileable_item, :file, :stretch, :style, :weight
  menu parent: 'Settings', priority: 4

  form :html => { :multipart => true } do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :fontfileable_item, :label => 'Font Family', :as => :select, :collection => (Font.all).map { |i| [ "#{i.class.to_s} - #{i.name}", "#{i.class.to_s}-#{i.id}"] }
      f.input :stretch
      f.input :style
      f.input :weight
      f.input :file, :as => :file
    end
    
    # f.inputs "Images" do |fm|
    #   fm.input :file, :as => :file
    # end
    actions
  end

end
