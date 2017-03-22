ActiveAdmin.register SharedTemplate do

  menu parent: 'Card Templates'
  actions :all, :except => [:new, :edit]

  config.per_page = 100

  controller do
    def scoped_collection
      super.includes :organization, :card_template, :clone_card_template
    end
  end

  batch_action :make_it_unique do |ids|
    error_cards = []
    success_cards = []
    
    SharedTemplate.find(ids).each do |st|
      res = st.make_it_unique
      res[0] ? success_cards << res[1] : error_cards << res[1]
    end
    flash[:notice] = "#{success_cards.join(', ')}!" unless success_cards.empty?
    flash[:error] = "#{error_cards.join(', ')}!" unless error_cards.empty?

    redirect_to :back
  end

  member_action :make_it_unique, method: :put do
    @shared_template = resource
    
    res = @shared_template.make_it_unique
    res[0] ? flash[:notice] = res[1] : flash[:error] = res[1]
    
    redirect_to :back
  end
  
  action_item :make_it_unique, :only => [:show] do
    link_to("Make it unique", make_it_unique_admin_shared_template_path(shared_template), method: :put, :class => "member_link")
  end

  index do
    selectable_column
    id_column
    column :card_template, :sortable => :card_template_id
    column ('From Organization') { |t| link_to(t.card_template.organization.name, admin_organization_path(t.card_template.organization)) }
    column 'Shared with organization', :organization, :sortable => :organization_id
    column 'As Card Template', :clone_card_template
    column '' do |c|
      link_to("Make it unique", make_it_unique_admin_shared_template_path(c), method: :put, :class => "member_link") +
      link_to("View", admin_shared_template_path(c), :class => "member_link") +
      link_to("Delete", admin_shared_template_path(c), method: :delete, 
        data: { confirm: 'Are you certain you want to delete this?' }, :class => "member_link")
    end

  end

  filter :card_template_organization_name_cont, as: :string, label: 'From Organization Name'
  filter :organization_name_cont, as: :string, label: 'Shared with Organization Name'
  filter :organization, label: 'Shared with'
  filter :card_template, label: 'Master card template'
  filter :clone_card_template, label: 'Cloned card template'

end
