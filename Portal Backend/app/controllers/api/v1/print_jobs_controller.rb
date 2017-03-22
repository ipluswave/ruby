class Api::V1::PrintJobsController < Api::V1::BaseController

  swagger_controller :print_jobs, "PrintJobs"

  swagger_api :index do |api|
    summary "Fetches all Print Jobs items"
    Api::V1::BaseController::add_page_params(api)
    Api::V1::BaseController::add_common_params(api)
    api.param :query, :status, :string, :optional, "Job status (active, printing, completed, failed)"
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
  end
  
  def index
    @print_jobs = PrintJob.where(organization_id: params[:organization_id])
    @print_jobs
  end

  swagger_api :create do |api|
    summary "Create a new Print Job item"
    Api::V1::BaseController::add_common_params(api)
    api.param :form, "print_job[name]", :string, :optional, "Name"
    api.param :form, "print_job[card_template_id]", :integer, :required, "Card Template Id"
    api.param :form, "print_job[status]", :integer, :required, "Status. Created (value 1) or Scheduled (2)"
    response :unauthorized
    response :not_acceptable
    response :unprocessable_entity
  end

  def create
    # TODO (HR): sync Job attributes with the ones available for the WSDL API
    # TODO (HR): organization ID can't come from the Card Template
    @print_job = PrintJob.from_params(print_jobs_params)
    @print_job.JSON_V1!
    @print_job.save!
    @print_job
  end
  
  def add_users
    @print_job = PrintJob.find(params[:id])
    @print_job.add_users(print_jobs_params[:list_users])
    @print_job.save!
    @print_job
  end
  
  def print
    @print_job = PrintJob.find(params[:id])
    @print_job.Scheduled!
    @print_job.charge_organization
    @print_job.save!
    @print_job
  end

  swagger_api :show do |api|
    summary "Fetches a single Print Job item"
    Api::V1::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "Print Job Id"
    response :ok, "Success", :CardTemplate
    response :unauthorized
    response :not_acceptable
    response :not_found
  end
  
  def show
    @print_job = PrintJob.find(params[:id])
  end

  private

    def print_jobs_params
      params.require(:print_job).permit(:card_template_id, :shipping_provider_id, :status, :list_users)
    end

end
