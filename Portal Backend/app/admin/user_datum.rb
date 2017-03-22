ActiveAdmin.register UserDatum, as: 'Print Cards' do
  # permit_params :list, :of, :attributes, :on, :model
  menu parent: 'Print Jobs'
  actions :all, :except => [:destroy, :new, :edit]
  config.per_page = 50

  controller do
    def scoped_collection
      super.includes :print_job, :card_template
    end
  end

  index do
    selectable_column
    id_column
    column (:organization) do |ud|
      link_to(ud.print_job.organization.name, admin_organization_path(ud.print_job.organization)) if ud.print_job.present?
    end
    column :card_template, :sortable => :card_template_id
    column (:data_1) do |ud|
      ud.data['DATA_1']
    end
    column (:data_2) do |ud|
      ud.data['DATA_2']
    end
    column (:data_1) do |ud|
      ud.data['DATA_3']
    end
    column :status
    column :print_job
    column :created_at
    actions
  end

  filter :status_cd, as: :select, collection: proc { UserDatum.statuses.hash }, label: 'Status'
  filter :card_template_organization_name_cont, as: :string, label: 'Organization Name'
  filter :card_template_name_cont, as: :string, label: 'Card Template Name'
  # filter :card_template
  filter :DATA_1_eq
  filter :DATA_2_eq
  filter :DATA_3_eq
  filter :created_at
  filter :updated_at
end
