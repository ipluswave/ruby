class Api::V2::CardTemplatesController < Api::V2::BaseController
  swagger_controller :contacts, "Card Templates"

  rescue_from(ActionController::UnpermittedParameters) do |pme|
    render json: {error: pme.params.map { |p| "Unknown parameter '" + p + "'" }}, status: :bad_request
  end

  rescue_from(ActiveRecord::RecordNotFound) do |pme|
    render json: {error: "Card Template not found"}, status: :not_found
  end

  swagger_api :index do |api|
    summary "Fetches all Card Templates items"
    Api::V2::BaseController::add_common_params(api)
    response :unauthorized
  end

  def index
    @card_templates = []
    # Only Approved (status_cd: 1)
    @organization.card_templates.where(status_cd: 1).each do |card_template|
      @card_templates << {
        id: card_template.id,
        name: card_template.name
      }
    end
    if @organization.shared_templates.present?
      @organization.shared_templates.each do |shared_template|
        card_template = shared_template.clone_card_template.present? ? shared_template.clone_card_template : shared_template.card_template
          if card_template.status
            @card_templates << {
              id: card_template.id,
              name: shared_template.card_template.name
            }
          end
      end
      @card_templates = @card_templates.sort_by{|ct| ct[:id]}
    end
  end

  swagger_api :fields do |api|
    summary "Return list of variable fields"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Card Template Id"
    response :unauthorized
    response :not_found
  end

  def fields
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
    if card_templates and !(@card_template = card_templates.select{ |card_template| card_template.id == params[:id].to_i}.first)
      raise ActiveRecord::RecordNotFound
    end
    render :json => @card_template.template_fields, :status => 200
  end
end