class Api::V2::CardsController < Api::V2::BaseController
  swagger_controller :contacts, "Cards"

  before_filter :is_valid_card_template? , :only => [:create, :update]

  rescue_from(ActionController::UnpermittedParameters) do |pme|
    render json: {error: pme.params.map { |p| "Unknown parameter '" + p + "'" }}, status: :bad_request
  end

  rescue_from(ActionController::ParameterMissing) do |pme|
    render json: {error: "Missing parameter '" + pme.param.to_s + "'"}, status: :bad_request
  end

  rescue_from(ActiveRecord::RecordNotFound) do |pme|
    render json: {error: "Card not found"}, status: :not_found
  end

  swagger_api :index do |api|
    summary "Fetches all Card items"
    Api::V2::BaseController::add_common_params(api)
    Api::V2::BaseController::add_page_params(api)
    response :unauthorized
  end

  def index
    @cards = @organization.cards
    if params[:page].present? && params[:page].to_i > 0 && params[:page_size].present? && params[:page_size].to_i > 0
      @cards = @cards.drop(params[:page_size].to_i * (params[:page].to_i - 1)).first(params[:page_size].to_i)
    end
  end

  swagger_api :show do |api|
    summary "Fetches a single Card Template item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Id"
    response :unauthorized
    response :not_found
  end

  def show
    @card = @organization.cards.find_by(id: params[:id])
    unless @card.present?
      raise ActiveRecord::RecordNotFound
    end
  end

  swagger_api :create do |api|
    summary "Create a new Card Template item"
    Api::V2::BaseController::add_common_params(api)
    api.param :form, "card[card_template_id]", :integer, :required, "Card Template Id"
    api.param :form, "card[data]", :string, :required, "Data"
    response :unauthorized
    response :bad_request
  end

  def create
    @card = @organization.cards.new(card_params)
    unless @card.save
      render :json => {error: @card.errors.full_messages}, :status => :bad_request
      return
    end
    @card
  end

  swagger_api :update do |api|
    summary "Update an existing Card Template item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Id"
    api.param :form, "card[card_template_id]", :integer, :optional, "Card Template Id"
    api.param :form, "card[data]", :string, :optional, "Data"
    response :unauthorized
    response :bad_request
    response :not_found
  end

  def update
    @card = @organization.cards.find_by(id: params[:id])
    unless @card.present?
      raise ActiveRecord::RecordNotFound
    end
    unless @card.update_attributes(card_params)
      render :json => {error: @card.errors.full_messages}, :status => :bad_request
      return
    end
    @card
  end

  swagger_api :destroy do |api|
    summary "Deletes an existing Card Template item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Id"
    response :unauthorized
    response :not_found
  end

  def destroy
    @card = @organization.cards.find_by(id: params[:id])
    unless @card.present?
      raise ActiveRecord::RecordNotFound
    end
    @card.destroy
    render :json => {result: "Success"}, :status => :ok
  end

  swagger_api :image do |api|
    summary "Upload images associated with a Card item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Id"
    api.param :form, "card[token]", :string, :required, "Token"
    api.param :body, "card[file]", :file, :required, "Image"
    response :unauthorized
    response :not_found
    response :bad_request
  end

  def image
    @card = @organization.cards.find_by(id: params[:id])
    unless @card.present?
      raise ActiveRecord::RecordNotFound
    end
    if params["card"].present? and params["card"]["token"].present? and params["card"]["file"].present?
      @card.add_file(params.require(:card).permit(:file, :token))
    end
  end

  swagger_api :preview do |api|
    summary "Preview the Card item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Id"
    response :unauthorized
    response :not_found
  end

  def preview
    card = @organization.cards.find_by(id: params[:id])
    unless card.present?
      raise ActiveRecord::RecordNotFound
    end

    begin
      screenshot = Screenshot.new
      front_ret = screenshot.capture_card_preview(card, "front")
      return {preview_available: false, front: '', back: ''} unless front_ret[0]

      front_preview_json = front_ret[1] if front_ret[0]
      
      if card.card_template.double_sided?
        back_ret = screenshot.capture_card_preview(card, "back")
        back_preview_json = back_ret[1] if back_ret[0]
      end
      
      preview_json = {preview_available: true}
      preview_json[:front] = front_preview_json
      preview_json[:back] = back_preview_json if back_preview_json.present?
      
      screenshot.reset_session
    rescue Exception => e
      Rails.logger.error("[API::V2::CARD_PREVIEW] Unable to capture card image preview. Message: #{e.message}")
      preview_json = {preview_available: false, front: '', back: ''}
    end
    
    render :json => preview_json
  end

  private

  def is_valid_card_template?
    if params[:card][:card_template_id].present?
      card_templates = []
      @organization.card_templates.where(status_cd: 1).each do |card_template|
        card_templates << card_template
      end
      if @organization.shared_templates.present?
        @organization.shared_templates.each do |shared_template|
          card_template = shared_template.clone_card_template.present? ? shared_template.clone_card_template : shared_template.card_template
          if card_template.status
            card_templates << card_template
          end
        end
      end
      if card_templates and !card_templates.select{ |card_template| card_template.id == params[:card][:card_template_id].to_i}.first
        render json: {error: "Card Template not found"}, :status => :not_found
      end
    end
  end

  def card_params
    params.require(:card).require(:card_template_id) unless params[:id].present?
    params.require(:card).require(:data) unless params[:id].present?
    permitted = params.require(:card).permit(:card_template_id, :data)
    if permitted[:data].present?
      permitted[:data] = JSON.parse(permitted[:data])
    end
    permitted
  end
end