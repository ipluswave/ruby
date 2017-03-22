class Api::V2::ApplicationController < ActionController::Base
  protected

  def authenticate_request!
    allowed_actions = %w(password_reset password_new)
    return true if allowed_actions.include?(params[:action])
    unless user_id_in_token?
      render json: {error: 'Not Authenticated'}
      return
    end
    @current_user = User.find(auth_token[:user_id])
  end

  private

  def http_token
    @http_token ||= if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    end
  end

  def auth_token
    @auth_token ||= JsonWebToken.decode(http_token)
  end

  def user_id_in_token?
    http_token && auth_token && auth_token[:user_id].to_i
  end
end
