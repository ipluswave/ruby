class Api::V2::AddressesController < Api::V2::BaseController

  swagger_controller :addresses, "Addresses"

  swagger_api :index do |api|
    summary "Fetches all Address items"
    Api::V2::BaseController::add_common_params(api)
    Api::V2::BaseController::add_page_params(api)
    response :unauthorized
    response :not_acceptable
    response :requested_range_not_satisfiable
  end

  def index
    @addresses = @organization.addresses
    if params[:page].present? && params[:page].to_i > 0 && params[:page_size].present? && params[:page_size].to_i > 0
      @addresses = @addresses.drop(params[:page_size].to_i * (params[:page].to_i - 1)).first(params[:page_size].to_i)
    end
    @addresses
  end

  swagger_api :show do |api|
    summary "Fetches a single Address item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Address ID"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  def show
    @address = @organization.addresses.find_by(id: params[:id])
    unless @address.present?
      render json: {error: 'Address not found'}, :status => 404
    end
  end

  swagger_api :create do |api|
    summary "Creates a new Address"
    Api::V2::BaseController::add_common_params(api)
    api.param :form, "address[contact_id]", :string, :optional, "Contact ID"
    api.param :form, "address[label]", :string, :optional, "Label"
    api.param_list :form, "address[primary]", :string, :required, "Primary", ["true", "false"]
    api.param :form, "address[address1]", :string, :required, "Address1"
    api.param :form, "address[address2]", :string, :optional, "Address2"
    api.param :form, "address[city]", :string, :required, "City"
    api.param :form, "address[state]", :string, :required, "State"
    api.param :form, "address[zip_code]", :string, :required, "Zip Code"
    api.param :form, "address[country]", :string, :required, "Country Code"
    response :unauthorized
    response :not_acceptable
  end

  def create
    if params[:address][:contact_id].present?
      unless @organization.contacts.find_by(id: params[:address][:contact_id])
        render json: {error: 'Unknown contact id'}, :status => 400
        return
      end
    end
    @address = @organization.addresses.new(address_params.merge({organization_name: @organization.name}))
    unless @address.save
      render :json => {error: @address.errors.full_messages}, :status => 400
      return
    end
    @address
  end

  swagger_api :update do |api|
    summary "Updates an existing Address"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Address ID"
    api.param :form, "address[contact_id]", :string, :optional, "Contact ID"
    api.param :form, "address[label]", :string, :optional, "Label"
    api.param_list :form, "address[primary]", :string, :optional, "Primary", ["true", "false"]
    api.param :form, "address[address1]", :string, :optional, "Address1"
    api.param :form, "address[address2]", :string, :optional, "Address2"
    api.param :form, "address[city]", :string, :optional, "City"
    api.param :form, "address[state]", :string, :optional, "State"
    api.param :form, "address[zip_code]", :string, :optional, "Zip Code"
    api.param :form, "address[country]", :string, :optional, "Country Code"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  def update
    @address = @organization.addresses.find_by(id: params[:id])
    unless @address.present?
      render json: {error: 'Address not found'}, :status => 404
      return
    end
    unless @address.update_attributes(address_params)
      render :json => {error: @address.errors.full_messages}, :status => 400
      return
    end
    @address
  end

  swagger_api :destroy do |api|
    summary "Deletes an existing Address item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Address ID"
    response :unauthorized
    response :not_found
  end

  def destroy
    @address = @organization.addresses.find_by(id: params[:id])
    unless @address.present?
      render json: {error: 'Address not found'}, :status => 404
      return
    end
    @address.destroy
    render :json => {result: "Success"}, :status => 200
  end

  private

  def address_params
    permitted = params[:address].present? ? params.require(:address).permit(:label, :primary, :address1, :address2, :city, :state, :zip_code, :country, :contact_id) : {}
  end

end
