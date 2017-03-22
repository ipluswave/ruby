class Api::V1::CardTemplatesController < Api::V1::BaseController

  swagger_controller :card_templates, "CardTemplates"

  swagger_api :index do |api|
    summary "Fetches all Card Template items"
    Api::V1::BaseController::add_page_params(api)
    Api::V1::BaseController::add_common_params(api)
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
  end
  
  def index
    @card_templates = CardTemplate.where(organization_id: params[:organization_id])
    
    # This access previlege won't be given for extra cards, at this moment
    # my_org = Organization.find(params[:organization_id])
    # unless my_org.extra_cards.empty?
    #   my_org.extra_cards.each do |ec|
    #     @card_templates << ec.card_template
    #   end
    # end
    
    @card_templates
  end
  
  swagger_api :create do |api|
    summary "Create a new Card Template item"
    Api::V1::BaseController::add_common_params(api)
    api.param :form, "card_template[name]", :string, :optional, "Name"
    api.param :form, "card_template[card_type_id]", :integer, :required, "Name"
    api.param :form, "card_template[front_data]", :string, :optional, "Card template Front Side data"
    api.param :form, "card_template[back_data]", :string, :optional, "Card template Back Side data"
    api.param :form, "card_template[options]", :string, :options, "Card template options"
    api.param :form, "card_template[template_fields]", :string, :options, "Card template, template fields"
    api.param :form, "card_template[card_data]", :string, :options, "Card template, card data (magstripe, barcode, qrcode...)"
    api.param :form, "card_template[special_handlings]", :string, :options, "List of Special Handlings"
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
  end
  
  def create
    @card_template = CardTemplate.new(card_template_params)
    @card_template.organization_id = params[:organization_id]
    @card_template.special_handlings = SpecialHandling.find(JSON.parse(params["card_template"]["special_handlings"]).collect { |item| item["id"] }) if params["card_template"]["special_handlings"].present?
    @card_template.save!
    @card_template
  end

  swagger_api :show do |api|
    summary "Fetches a single Card Template item"
    Api::V1::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Template Id"
    response :ok, "Success", :CardTemplate
    response :unauthorized
    response :not_acceptable
    response :not_found
  end
  
  def show
    @card_template = CardTemplate.find(params[:id])
  end
  
  swagger_api :update do |api|
    summary "Update an existing Card Template item"
    Api::V1::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Template Id"
    api.param :form, "card_template[name]", :string, :optional, "Name"
    api.param :form, "card_template[card_type_id]", :integer, :optional, "Name"
    api.param :form, "card_template[front_data]", :string, :optional, "Card template Front Side data"
    api.param :form, "card_template[back_data]", :string, :optional, "Card template Back Side data"
    api.param :form, "card_template[options]", :string, :options, "Card template options"
    api.param :form, "card_template[template_fields]", :string, :options, "Card template, template fields"
    api.param :form, "card_template[card_data]", :string, :options, "Card template, card data (magstripe, barcode, qrcode...)"
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
    response :no_content
  end
  
  def update
    @card_template = CardTemplate.find(params[:id])
    if @card_template.update_attributes(card_template_params)
      @card_template.special_handlings = SpecialHandling.find(JSON.parse(params["card_template"]["special_handlings"]).collect { |item| item["id"] }) if params["card_template"]["special_handlings"].present?
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  swagger_api :destroy do |api|
    summary "Deletes an existing Card Template item"
    Api::V1::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Template Id"
    response :unauthorized
    response :not_found
    response :no_content
  end
  
  def destroy
    CardTemplate.destroy(params[:id])
    head :no_content
  end

  # This is not working Swagger 1.2
  # swagger_api :upload do |api2|
  #   summary "Upload an image to an existing Card Template item"
  #   Api::V1::BaseController::add_common_params(api2)
  #   api2.param :path, :id, :integer, :required, "Card Template Id"
  #   # api2.param :body, :image, :file, :required, "Image"
  #   response :unauthorized
  #   response :not_found
  #   response :no_content
  # end

  def upload
    Rails.logger.info("[AWS Credentials]: #{ENV['AWS_ACCESS_KEY_ID']} - #{ENV['AWS_SECRET_ACCESS_KEY']} - #{ENV['AWS_BUCKET']}")
    @card_template = CardTemplate.find(params[:id])
    if params["card_template"].present? and params["card_template"]["images"].present?
      @card_template.add_files(params["card_template"]["images"])
    end
  end

  private

    def card_template_params
      permitted = params.require(:card_template).permit(:name, :card_type_id, :front_data, :back_data, :images, :options, :template_fields, :card_data)
      # Permit card_template id for the create action, when is for legacy numbers
      # TODO (HR): after the migration this permission should be removed
      permitted = permitted.merge params.require(:card_template).permit(:id) if (params[:card_template][:id].present? && params[:card_template][:id].to_i < 9999)
      permitted
    end
end
