ActiveAdmin.register LabelTemplate do
  permit_params :organization_id, :type_cd, :template, :to_address
  menu parent: 'Settings', priority: 9

  action_item :design, only: :show do
    link_to("Design", design_admin_label_template_path(label_template), :class => "member_link")
  end

  member_action :design, method: :get do
    @label_template = resource
  end

  member_action :save_design, method: :post do
    @label_template = resource
    @label_template.template = params["label_template"]["template"]
    @label_template.to_address = params['label_template']['to_address']
    @label_template.save
    redirect_to design_admin_label_template_path(@label_template), notice: "Label template saved successfully!"
  end
  
  index do
    selectable_column
    id_column
    column :organization
    column :type
    column :updated_at
    column '' do |c|
      link_to("Design", design_admin_label_template_path(c), :class => "member_link") +
      link_to("View", admin_label_template_path(c), :class => "member_link") +
      link_to("Edit", edit_admin_label_template_path(c), :class => "member_link") +
      link_to("Delete", admin_label_template_path(c), method: :delete, 
        data: { confirm: 'Are you certain you want to delete this?' }, :class => "member_link")
    end

  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :organization
      input :type_cd, :label => 'Type', :as => :select, :collection => LabelTemplate.types.hash
      
      input :template
      input :to_address
    end

    panel 'Label Template replaceable attributes' do
      render partial: "template_examples", locals: {label_template: label_template}
    end

    actions
  end

  show do
    attributes_table do
      row :id
      row :organization
      row :type
      row :template
      row :to_address

      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  filter :organization_name_cont, as: :string, label: 'Organization Name'
  filter :organization
  filter :template
  filter :type_cd, as: :select, collection: proc { LabelTemplate.types.hash }, label: 'Type'
  filter :created_at
  filter :updated_at
  
end
