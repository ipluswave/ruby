ActiveAdmin.register User do

  permit_params do
    params = [:email, :pin, :organization_id, :locked_at, :role_ids => []]
    params.push :password unless @_params[:user].present? and @_params[:user][:password].empty?
    params.push :password_confirmation unless @_params[:user].present? and @_params[:user][:password_confirmation].empty?
    params
  end

  controller do
    def scoped_collection
      super.includes :organization
    end
  end

  index do
    selectable_column
    id_column
    column :email
    column :organization
    column (:role) { |u| u.roles.first.name }
    column :last_sign_in_at
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end
  
  # TODO (HR): create show action to add a list of roles

  filter :email
  filter :organization_name_cont, label: 'Organization name'
  filter :organization
  filter :roles,  :as => :select,:collection => Role.all(),label: 'Role'
  filter :current_sign_in_at
  filter :last_sign_in_at
  # filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs "User Details" do
      f.input :organization
      f.input :email
      f.input :roles, 
        :as => :check_boxes,
        :collection => Role.where("name in ('master', 'operator', 'admin')")
      f.input :pin
      f.input :password
      f.input :password_confirmation
      f.input :locked_at, :as => :string
    end
    f.actions
  end

end
