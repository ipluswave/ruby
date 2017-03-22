class Api::V2::PrintJobsController < Api::V2::BaseController
  swagger_controller :contacts, "PrintJobs"

  rescue_from(ActionController::UnpermittedParameters) do |pme|
    render json: {error: pme.params.map { |p| "Unknown parameter '" + p + "'" }}, status: :bad_request
  end

  rescue_from(ActionController::ParameterMissing) do |pme|
    render json: {error: "Missing parameter '" + pme.param.to_s + "'"}, status: :bad_request
  end

  rescue_from(ActiveRecord::RecordNotFound) do
    render json: {error: "Print Job not found"}, status: :not_found
  end

  swagger_api :index do |api|
    summary "Fetches all Print Jobs items"
    Api::V2::BaseController::add_common_params(api)
    Api::V2::BaseController::add_page_params(api)
    api.param :query, :status, :string, :optional, "Job status (Created: 0, Scheduled: 1)"
    response :unauthorized
    response :not_found
  end

  def index
    @print_jobs = @organization.print_jobs
    if params[:status].present?
      @print_jobs.where(status_cd: params[:status])
    end
    if params[:page].present? && params[:page].to_i > 0 && params[:page_size].present? && params[:page_size].to_i > 0
      @print_jobs = @print_jobs.drop(params[:page_size].to_i * (params[:page].to_i - 1)).first(params[:page_size].to_i)
    end
  end

  swagger_api :show do |api|
    summary "Fetches a single Print Job item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    response :unauthorized
    response :not_found
  end

  def show
    @print_job = @organization.print_jobs.find_by(id: params[:id])
    unless @print_job.present?
      raise ActiveRecord::RecordNotFound
    end
  end

  swagger_api :create do |api|
    summary "Create a new Print Job item"
    Api::V2::BaseController::add_common_params(api)
    api.param :form, "print_job[address_id]", :integer, :required, "Address Id"
    api.param :form, "print_job[shipping_provider_id]", :integer, :required, "Shipping Provider Id"
    api.param :form, "print_job[card_template_id]", :integer, :optional, "Card Template id"
    response :unauthorized
    response :bad_request
  end

  def create
    unless @organization.addresses.find_by(id: params[:print_job][:address_id])
      render :json => {error: "Address not found"}, :status => :not_found
      return
    end
    unless ShippingProvider.find_by(id: params[:print_job][:shipping_provider_id])
      render :json => {error: "Shipping Provider not found"}, :status => :not_found
      return
    end
    @print_job = @organization.print_jobs.new(print_jobs_params)
    @print_job.JSON_V2!
    unless @print_job.save
      render :json => {error: @print_job.errors.full_messages}, :status => :bad_request
      return
    end
    @print_job
  end

  swagger_api :update do |api|
    summary "Update an existing Print Job item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    api.param :form, "print_job[address_id]", :integer, :optional, "Address Id"
    api.param :form, "print_job[shipping_provider_id]", :integer, :optional, "Shipping Provider Id"
    response :unauthorized
    response :not_found
    response :bad_request
  end

  def update
    @print_job = @organization.print_jobs.find_by(id: params[:id])
    unless @print_job.present?
      raise ActiveRecord::RecordNotFound
    end
    if params[:print_job][:address_id].present? and !@organization.addresses.find_by(id: params[:print_job][:address_id])
      render :json => {error: "Address not found"}, :status => :not_found
      return
    end
    if params[:print_job][:shipping_provider_id].present? and !ShippingProvider.find_by(id: params[:print_job][:shipping_provider_id])
      render :json => {error: "Shipping Provider not found"}, :status => :not_found
      return
    end
    unless @print_job.update_attributes(print_jobs_params)
      render :json => {error: @print_job.errors.full_messages}, :status => :bad_request
      return
    end
    @print_job
  end

  swagger_api :add_cards do |api|
    summary "Add cards to the Print Job item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    api.param :form, "print_job[card_ids]", :string, :required, "Card Id's"
    response :unauthorized
    response :not_found
    response :bad_request
  end

  def add_cards
    @print_job = @organization.print_jobs.find_by(id: params[:id])
    unless @print_job.present?
      raise ActiveRecord::RecordNotFound
    end
    cards = @organization.cards.where(id: print_jobs_params[:card_ids])
    if cards.count != print_jobs_params[:card_ids].count
      render :json => {error: "Card not found"}, :status => :not_found
      return
    end
    @print_job.add_cards(cards)
    @print_job.total_cards = @print_job.total_cards_shortcut
    @print_job.save!
    @print_job
  end

  swagger_api :remove_cards do |api|
    summary "Remove a card from the Print Job item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    api.param :path, :card_id, :integer, :required, "Card Id"
    response :unauthorized
    response :not_found
    response :internal_server_error
  end

  def remove_cards
    @print_job = @organization.print_jobs.where(id: params[:id], status_cd: 0).first
    unless @print_job.present?
      render :json => false, :status => :not_found
      return
    end
    user_data = @print_job.list_users.first.user_datum.where(card_id: params[:card_id]).first
    if user_data
      unless user_data.destroy
        render :json => false, :status => :internal_server_error
        return
      end
      @print_job.total_cards = @print_job.total_cards_shortcut
      @print_job.save!
    end
    render :json => true
  end

  swagger_api :print do |api|
    summary "Submit Print Job"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    response :unauthorized
    response :not_found
    response :bad_request
  end

  def print
    @print_job = @organization.print_jobs.find_by(id: params[:id])
    unless @print_job.present?
      raise ActiveRecord::RecordNotFound
    end
    @print_job.Scheduled!
    @print_job.charge_organization
    unless @print_job.save
      render :json => {error: @print_job.errors.full_messages}, :status => :bad_request
      return
    end
    @print_job
  end

  swagger_api :check_balance do |api|
    summary "Submit Print Job"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    response :unauthorized
    response :not_found
    response :bad_request
  end

  def check_balance
    @print_job = @organization.print_jobs.find_by(id: params[:id])
    unless @print_job.present?
      raise ActiveRecord::RecordNotFound
    end
    render :json => true
  end

  private

  def print_jobs_params
    params.require(:print_job).require(:shipping_provider_id) if params[:action] == 'create'
    params.require(:print_job).require(:address_id) if params[:action] == 'create'
    params.require(:print_job).require(:card_ids) if params[:action] == 'add_card'
    permitted = params.require(:print_job).permit(:card_template_id, :address_id, :shipping_provider_id, :card_ids)
    if permitted[:card_ids].present?
      permitted[:card_ids] = JSON.parse(permitted[:card_ids])
    end
    permitted
  end
end