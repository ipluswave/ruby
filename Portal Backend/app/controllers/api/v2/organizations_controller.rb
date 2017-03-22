class Api::V2::OrganizationsController < Api::V2::BaseController
  swagger_controller :organizations, "Organizations"

  rescue_from(ActionController::UnpermittedParameters) do |pme|
    render json: {error: pme.params.map { |p| "Unknown parameter '" + p + "'" }}, status: :bad_request
  end

  rescue_from(ActiveRecord::RecordNotFound) do |pme|
    render json: {error: "Organization not found"}, status: :not_found
  end

  swagger_api :show do |api|
    summary "Fetches a single Organization item"
    api.param :path, :id, :integer, :required, "Organization ID"
    response :unauthorized
    response :not_found
  end

  def show
    @organization = current_user.organization
    if @organization and !@organization.id.eql? params[:id].to_i
      raise ActiveRecord::RecordNotFound
    end
  end

  swagger_api :update do |api|
    summary "Updates an existing Organization"
    api.param :path, :id, :integer, :required, "Organization ID"
    api.param :form, "organization[settings]", :string, :optional, "Settings"
    response :unauthorized
    response :bad_request
    response :not_found
  end

  def update
    @organization = current_user.organization
    if @organization and !@organization.id.eql? params[:id].to_i
      raise ActiveRecord::RecordNotFound
    end
    unless @organization.update_attributes(organization_params)
      render :json => {error: @organization.errors.full_messages}, :status => :bad_request
      return
    end
    @organization
  end

  swagger_api :balance do |api|
    summary "Get Organization balance"
    api.param :path, :id, :integer, :required, "Organization ID"
    response :unauthorized
    response :not_found
  end

  def balance
    organization = current_user.organization
    if organization and !organization.id.eql? params[:id].to_i
      raise ActiveRecord::RecordNotFound
    end
    @balance = organization.balance
  end

  swagger_api :shipping_providers do |api|
    summary "Get list of available Shipping Provider"
    api.param :path, :id, :integer, :required, "Organization ID"
    response :unauthorized
    response :not_found
  end

  def shipping_providers
    organization = current_user.organization
    if organization and !organization.id.eql? params[:id].to_i
      raise ActiveRecord::RecordNotFound
    end
    @shipping_providers = ShippingProvider.all
  end

  private

  def organization_params
    permitted = params[:organization].present? ? params.require(:organization).permit(:settings) : {}
  end

end