ActiveAdmin.register Printer do
  permit_params :name, :workstation_id, :print_label, :print_letter, :card_type_ids => []
  menu parent: 'Print Locations', priority: 3

  controller do
    def scoped_collection
      super.includes :site, :workstation
    end
  end
  
  member_action :update_no_redir, method: :put do
    resource.update(permitted_params["printer"])
    render plain: "OK"
  end

  index do
    selectable_column
    id_column
    column :name
    column :site
    column :workstation
    column :updated_at
    actions
  end

  show do |p|
    attributes_table do
      row :id
      row :name
      row :site
      row :workstation
      row :print_label
      row :print_letter
      row :updated_at
    end
    
    panel "Card Types" do
      table_for p.card_types do |ct|
        column :name
        column :updated_at
        column 'Actions' do |o|
          link_to('Show', admin_card_type_path(o), :class => "member_link") +
          link_to('Edit', edit_admin_card_type_path(o), :class => "member_link")
        end
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :name
      input :workstation
      input :print_label, :as => :select
      input :print_letter, :as => :select
      input :card_types, :as => :check_boxes, :multiple => :true, :collection => CardType.all, :input_html => { :class => 'printer-form-card-types' }
    end
    actions
  end

  filter :workstation
  filter :site
  filter :name
  filter :card_type
  filter :print_label
  filter :print_letter
  filter :created_at
  filter :updated_at

end
