class Api::V2::ContactsController < Api::V2::BaseController

  swagger_controller :contacts, "Contacts"

  swagger_api :index do |api|
    summary "Fetches all Contact items"
    Api::V2::BaseController::add_common_params(api)
    Api::V2::BaseController::add_page_params(api)
    response :unauthorized
    response :not_acceptable
    response :requested_range_not_satisfiable
  end

  def index
    @contacts = @organization.contacts
    if params[:page].present? && params[:page].to_i > 0 && params[:page_size].present? && params[:page_size].to_i > 0
      @contacts = @contacts.drop(params[:page_size].to_i * (params[:page].to_i - 1)).first(params[:page_size].to_i)
    end
    @contacts
  end

  swagger_api :show do |api|
    summary "Fetches a single Contact item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Contact ID"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  def show
    @contact = @organization.contacts.find_by(id: params[:id])
    unless @contact.present?
      render json: {error: 'Contact not found'}, :status => 404
      return
    end
  end

  swagger_api :create do |api|
    summary "Creates a new Contact"
    Api::V2::BaseController::add_common_params(api)
    api.param :form, "contact[full_name]", :string, :required, "Full name"
    api.param :form, "contact[email]", :string, :required, "Email"
    api.param :form, "contact[alt_email]", :string, :optional, "Alt email"
    api.param :form, "contact[phone_number]", :string, :required, "Phone number"
    api.param :form, "contact[alt_phone_number]", :string, :optional, "Alt phone number"
    api.param :form, "contact[fax_number]", :string, :optional, "Fax number"
    response :unauthorized
    response :not_acceptable
  end

  def create
    @contact = @organization.contacts.new(contact_params)
    unless @contact.save
      render :json => {error: @contact.errors.full_messages}, :status => 400
      return
    end
    @contact
  end

  swagger_api :update do |api|
    summary "Updates an existing Contact"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Contact ID"
    api.param :form, "contact[full_name]", :string, :optional, "Full name"
    api.param :form, "contact[email]", :string, :optional, "Email"
    api.param :form, "contact[alt_email]", :string, :optional, "Alt email"
    api.param :form, "contact[phone_number]", :string, :optional, "Phone number"
    api.param :form, "contact[alt_phone_number]", :string, :optional, "Alt phone number"
    api.param :form, "contact[fax_number]", :string, :optional, "Fax number"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  def update
    @contact = @organization.contacts.find_by(id: params[:id])
    unless @contact.present?
      render json: {error: 'Contact not found'}, :status => 404
      return
    end
    unless @contact.update_attributes(contact_params)
      render :json => {error: @contact.errors.full_messages}, :status => 400
      return
    end
    @contact
  end

  swagger_api :destroy do |api|
    summary "Deletes an existing Contact item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Contact ID"
    response :unauthorized
    response :not_found
  end

  def destroy
    @contact = @organization.contacts.find_by(id: params[:id])
    unless @contact.present?
      render json: {error: 'Contact not found'}, :status => 404
      return
    end
    if @contact.addresses.present?
      render :json => {error: 'Contact is associated with an addresses'}, :status => 400
      return
    end
    @contact.destroy
    render :json => {result: "Success"}, :status => 200
  end

  private

  def contact_params
    permitted = params[:contact].present? ? params.require(:contact).permit(:full_name, :email, :alt_email, :phone_number, :alt_phone_number, :fax_number) : {}
  end

end