class Api::V2::BaseController < Api::V2::ApplicationController
  before_filter :authenticate_request!
  before_filter :get_organization

  def get_organization
    if params[:organization_id].present?
      @organization = current_user.organization if current_user.organization.present?
      if @organization and !@organization.id.eql? params[:organization_id].to_i
        render json: {error: 'Organization not found'}, :status => :not_found
      end
    end
  end

  def self.add_page_params(api)
    api.param :query, :page, :integer, :optional, "Page number"
    api.param :query, :page_size, :integer, :optional, "Page size"
  end

  def self.add_common_params(api)
    api.param :path, :organization_id, :integer, :required, "Organization ID"
  end
end
