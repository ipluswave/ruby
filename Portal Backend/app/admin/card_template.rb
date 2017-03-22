ActiveAdmin.register CardTemplate do
  permit_params :name, :source, :organization_id, :status_cd, :card_type_id, :front_data, :back_data, :options, :template_fields, :card_data, :img, :master_card_template_id, special_handling_ids: [], shared_templates_attributes: [:id, :organization_id, :card_template_id, :_destroy]
  menu priority: 3

  scope "All", :card_template_is_all, default: true
  scope "Draft", :card_template_is_draft
  scope "Approved", :card_template_is_approved
  scope "Cloned", :card_template_is_cloned

  batch_action :approve do |ids|
    cart_templates = CardTemplate.where('id IN (?) AND status_cd = 0', ids)
    cart_templates.each do |ct|
      ct.status_cd = 1
      ct.save
    end
    flash[:notice] = "Successfully approved #{cart_templates.length} card templates"
    redirect_to :back
  end

  batch_action :destroy do |ids|
    card_templates = CardTemplate.where('id IN (?)', ids)
    card_templates.each do |ct|
      ct.destroy
    end
    redirect_to :back
  end

  controller do
    def scoped_collection
      super.includes :organization, :card_type
    end
    
    def update
      if params[:card_template][:share_with_all].length > 1
        # Convert hash to array to make it possible to dynamically add new rows
        params[:card_template][:shared_templates_attributes] = params[:card_template][:shared_templates_attributes].present? ? params[:card_template][:shared_templates_attributes].values : []
        already_shared_with = params[:card_template][:shared_templates_attributes].collect { |shared_template| shared_template[:organization_id].to_i }
        
        Organization.organizations_tree(resource).each do |organization|
          unless already_shared_with.include?(organization.id)
            params[:card_template][:shared_templates_attributes] << {
              organization_id: organization.id,
              _destroy: 0
            }
          end
        end
      end
      
      super
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to request.referer[/(card_templates\/[0-9]+)$/].nil? ? :back : collection_url }
      end
    end
  end

  member_action :preview, method: :get do
    @card_template = resource
    @card_template = @card_template.master_card_template if @card_template.Cloned?
    ud = @card_template.preview_data
    unless ud.present?
      ud = UserDatum.new({card_template_id: @card_template.id})
      ud.data = {}
      ud.save!
    end

    # This code was used during the migration and right after the migration
    # [HR] Delete if not used after 06/10/2017
    # if @card_template.id < 9999
    #   begin
    #     client = Savon::Client.new(wsdl: ENV['legacy_preview_root'])
    #     wsdl_user = @card_template.organization.users.first
    #     basic_params = { "email" => wsdl_user.email.upcase, "CompanyPIN" => wsdl_user.pin, "CardRefNum" => @card_template.id, "CardWidth" => 400}
    #     front_side_params = ud.to_wsdl_params(basic_params.merge({"CardSide" => 0}))
    #     back_side_params = ud.to_wsdl_params(basic_params.merge({"CardSide" => 1})) if @card_template.double_sided?
    #     
    #     @front_preview_legacy_image = client.call(:preview_card, message: front_side_params)
    #     @front_preview_legacy_image = @front_preview_legacy_image.to_hash[:preview_card_response][:return]
    #     
    #     if @card_template.double_sided?
    #       @back_preview_legacy_image = client.call(:preview_card, message: back_side_params)
    #       @back_preview_legacy_image = @back_preview_legacy_image.to_hash[:preview_card_response][:return]
    #     end
    #     
    #     card_fields_response = client.call(:card_fields, message: basic_params)
    #     card_fields = card_fields_response.to_hash[:card_fields_response][:return].gsub(/~200~.*/,"").gsub(/#~0~/,"")
    #     if card_fields
    #       card_fields_items = card_fields.split('#')
    #       unless card_fields_items[0].match(/~/)
    #         card_fields_items.shift
    #       end
    #       @card_fields_items = card_fields_items.collect { |i| i.gsub(/~.~/, "") }
    #     end
    #     
    #     image_sizes_response = client.call(:image_sizes, message: basic_params)
    #     image_sizes = image_sizes_response.to_hash[:image_sizes_response][:return].match(/(.*)\#(.*)\#(.*)\#(.*)\#/)
    #     if image_sizes.present?
    #       if image_sizes[1].to_i > 0
    #         @card_fields_items << 'Portrait'
    #       end
    #       if image_sizes[3].to_i > 0
    #         @card_fields_items << 'Signature'
    #       end
    #     end
    #   rescue Exception => e
    #     Rails.logger.error("Unable to capture card image preview from legacy system. Message: #{e.message}")
    #   end
    # end

    @user_data_id = ud.id
  end
  
  member_action :upload, method: :post do
    image = MiniMagick::Image.open(params[:img].path)

    iu = ImageUploader.new
    iu.store!(params[:img])
    
    card_template = CardTemplate.find(params[:card_template_id])
    ud = card_template.preview_data
    if ud.data[params["token"]].present? && ud.data[params["token"]].match(/amazonaws.com/)
      s3 = Aws::S3::Client.new
      resp = s3.delete_object({
        bucket: ENV['AWS_BUCKET'],
        key: ud.data[params["token"]].match(/.*\.com\/(.*)/)[1]
      })
    end
    ud.data[params["token"]] = iu.url
    ud.save!
    
    return_json = {
			status:"success",
			url:iu.url,
			width:image[:width],
			height:image[:height]
    }
    render json: return_json
  end
  
  member_action :crop, method: :post do
    image_url = params["imgUrl"].match(/http/).present? ? params["imgUrl"] : "#{env['HTTP_ORIGIN']}#{params['imgUrl']}"
    img = MiniMagick::Image.open(image_url)
    img.resize "#{params['imgW']}x#{params['imgH']}"
    img.crop "#{params["cropW"].to_i}x#{params["cropH"].to_i}+#{params["imgX1"].to_i}+#{params["imgY1"].to_i}"
    
    iu = ImageUploader.new
    iu.store!(img)
    
    card_template = CardTemplate.find(params[:id])
    ud = card_template.preview_data
    if ud.data[params["token"]].present? && ud.data[params["token"]].match(/amazonaws.com/)
      s3 = Aws::S3::Client.new
      resp = s3.delete_object({
        bucket: ENV['AWS_BUCKET'],
        key: ud.data[params["token"]].match(/.*\.com\/(.*)/)[1]
      })
    end

    ud.data[params["token"]] = iu.url
    ud.save!

    return_json = {
			status:"success",
			url:iu.url,
    }
    render json: return_json
  end
  
  member_action :save_card_preview_data, method: :post do
    @card_template = resource
    ud = @card_template.preview_data
    ud ||= UserDatum.new({card_template_id: @card_template.id}) 
    ud.data = ud.data.merge(params["user_data"]) if params["user_data"].present?
    ud.fix_data
    ud.save!
    redirect_to preview_admin_card_template_path(@card_template), notice: "Card preview data saved successfully!"
  end

  member_action :print_sample, method: :post do
    @card_template = resource

    new_print_job = PrintJob.from_card_template(resource)

    redirect_to preview_admin_card_template_path(@card_template), notice: "Sample card sent for printing!"
  end
  
  member_action :design, method: :get do
    @card_template = resource
    @to_load = {org_id: @card_template.organization_id, card_template_id: @card_template.id}
  end
  
  action_item :preview, only: :show do
    link_to("Preview", preview_admin_card_template_path(card_template), :class => "member_link")
  end

  action_item :design, only: :show do
    link_to("Design", design_admin_card_template_path(card_template), :class => "member_link")
  end

  index do
    selectable_column
    id_column
    column :name
    column :organization
    column :status, :sortable => :status_cd do |o|
      case o.status
      when :Draft
        status_tag( 'Draft', :yellow )
      when :Approved
        status_tag( 'Approved', :ok )
      when :Cloned
        status_tag( 'Cloned', :red )
      else
        ""
      end
    end

    column :card_type
    column "Special Handling tokens", :extended_special_handlings_tokens 
    column :created_at
    column :updated_at
    column '' do |c|
      link_to("Preview", preview_admin_card_template_path(c), :class => "member_link") +
      link_to("Design", design_admin_card_template_path(c), :class => "member_link") +
      link_to("View", admin_card_template_path(c), :class => "member_link") +
      link_to("Edit", edit_admin_card_template_path(c), :class => "member_link") +
      link_to("Delete", admin_card_template_path(c), method: :delete, 
        data: { confirm: 'Are you certain you want to delete this?' }, :class => "member_link")
    end
  end

  show do |ct|
    attributes_table do
      row :id
      row :name
      row :organization
      row :card_type
      row :status
      row :front_data
      row :back_data
      row :options
      row :template_fields
      row :card_data
      row :master_card_template
      
      row :created_at
      row :updated_at

    end

    panel "Special Handlings" do
      table_for ct.extended_special_handlings do |s|
        column :name
        column :token
        column :description
      end
    end

    panel "Other Organizations" do
      table_for ct.shared_templates do |s|
        column (:id) do |o|
          o.organization.id
        end
        column (:name) do |o|
          o.organization.name
        end
        column (:updated_at) do |o|
          o.organization.updated_at
        end
        column 'Actions' do |o|
          link_to('Show', admin_organization_path(o.organization), :class => "member_link")
        end
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    inputs do
      input :name
      input :status_cd, :label => 'Status', as: :select, :collection => {Draft: 0, Approved: 1}, :include_blank => false
      input :card_type
      input :organization, :as => :select, :collection => resource.shared_templates.present? ? Organization.organizations_tree(resource, false) : Organization.all
      input :special_handlings,
        :as => :check_boxes,
        :multiple => :true,
        :input_html => { :class => "multiple-select" }
    end
    actions

    unless f.object.new_record? or resource.Cloned?
      panel "Shared with other Organizations" do
        inputs class: 'share-with-others-container' do
          f.input :share_with_all, :label => 'All organizations inside organization tree', :as => :check_boxes, :collection => [['', '1']], :hidden_fields => false
          f.has_many :shared_templates, heading: false do |t|
            t.input :organization, collection: (Organization.organizations_tree(resource))
            t.input :_destroy, :as => :boolean, :required => false, :label => 'Remove'
          end
        end
      end
      actions
    end
    
    panel "Low Level details" do
      inputs do
        input :front_data
        input :back_data
        input :options_str
        input :template_fields_str
        input :card_data_str
        input :master_card_template
      end
    end

    actions
  end

  filter :organization_name_cont, as: :string, label: 'Organization Name'
  filter :organization
  filter :card_type
  filter :name
  filter :special_handlings
  filter :created_at
  filter :updated_at

end
