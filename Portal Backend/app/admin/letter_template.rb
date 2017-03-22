ActiveAdmin.register LetterTemplate do
  permit_params :organization_id, :template, :name, :paper_type, :page_size, :orientation, :margin_top, :margin_bottom, 
    :margin_left, :margin_right, :font_id, :font_size, :line_height
  menu parent: 'Settings', priority: 8

  action_item :design, only: :show do
    link_to("Design", design_admin_letter_template_path(letter_template), :class => "member_link")
  end

  action_item :view, only: :design do
    link_to "View", admin_letter_template_path
  end

  action_item :edit, only: :design do
    link_to "Edit", edit_admin_letter_template_path
  end

  action_item :delete, only: :design do
    link_to("Delete", admin_letter_template_path, method: :delete, data: {confirm: 'Are you certain you want to delete this?' })
  end

  member_action :design, method: :get do
    @letter_template = resource
  end

  member_action :save_design, method: :post do
    @letter_template = resource
    @letter_template.template = params["letter_template"]["template"]
    @letter_template.save
    redirect_to design_admin_letter_template_path(@letter_template), notice: "Letter template saved successfully!"
  end
  
  member_action :convert, method: :get do
    resource.change_replaceable_tokens
    resource.save
    redirect_to admin_letter_templates_path, notice: "Letter template '#{resource.name}' converted successfully!"
  end

  index do
    selectable_column
    id_column
    column :organization
    column :name
    column :paper_type
    column :paper_size
    column :created_at
    column :updated_at
    column '' do |c|
      link_to("Convert", convert_admin_letter_template_path(c), :class => "member_link") +
      link_to("Design", design_admin_letter_template_path(c), :class => "member_link") +
      link_to("View", admin_letter_template_path(c), :class => "member_link") +
      link_to("Edit", edit_admin_letter_template_path(c), :class => "member_link") +
      link_to("Delete", admin_letter_template_path(c), method: :delete,
        data: { confirm: 'Are you certain you want to delete this?' }, :class => "member_link")
    end

  end
  
  show do
    attributes_table do
      row :id
      row :name
      row :paper_type
      row :page_size
      row :orientation
      row :organization
      row :margin_top
      row :margin_bottom
      row :margin_left
      row :margin_right
      row :font
      row :font_size
      row :line_height
      row :template
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :organization
      input :name
      input :paper_type
      input :page_size, :as => :select, :collection => ['A4', 'Letter']
      input :orientation, :as => :select, :collection => ['Portrait', 'Landscape']
      input :margin_top
      input :margin_bottom
      input :margin_left
      input :margin_right
      input :font
      input :font_size, :label => 'Font Size (px)'
      input :line_height, :label => 'Line Height (px)'
      input :template
    end
    actions
  end

  filter :name
  filter :paper_type
  filter :organization_name_cont, as: :string, label: 'Organization Name'
  filter :organization
  filter :template
  filter :created_at
  filter :updated_at
  
end
