class Api::V1::CardTypesController < Api::V1::BaseController

  swagger_controller :card_types, "CardType"

  swagger_api :index do |api|
    summary "Fetches all Card Type items"
    Api::V1::BaseController::add_page_params(api)
    Api::V1::BaseController::add_common_params(api, :optional)
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
  end
  
  def index
    @card_types = params[:organization_id].present? ? CardType.includes(:organizations).where(:organizations => {:id => [params[:organization_id], nil]}).order(:id) : CardType.all
    @card_types
  end
  
end
