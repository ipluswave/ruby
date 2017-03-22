class Api::V1::BaseController < ActionController::Base
  before_action :authenticate_user! if ENV['LOCK_API'].present?

  def self.add_page_params(api)
    api.param :query, :page, :integer, :optional, "Page number"
    api.param :query, :page_size, :integer, :optional, "Page size"
  end

  def self.add_common_params(api, level = :required)
    api.param :query, :organization_id, :string, :required, "ID of the Organization"
  end

end
