class Api::V1::OrganizationsController < Api::V1::BaseController

  swagger_controller :organizations, "Organizations"

  swagger_api :index do |api|
    summary "Fetches all Organizations items"
    Api::V1::BaseController::add_page_params(api)
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
  end

  def index
    @organizations = Organization.all
  end
  
  def letters
    organization = Organization.find(params[:id])
    @letters = organization.letter_templates
    @letters += LetterTemplate.global
  end
  
  def fonts
    organization = Organization.find(params[:id])
    @fonts = organization.fonts
    @fonts += Font.global
  end
  
  def special_handlings
    @special_handlings = SpecialHandling.where(:organization_id => params[:id])
    @special_handlings += SpecialHandling.global
  end
  
end
