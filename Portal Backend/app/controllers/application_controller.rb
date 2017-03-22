class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def access_denied(exception)
    redirect_to admin_dashboard_path, :alert => exception.message
  end
  
  def access_role_filter
    # Only Master and Operator are allowed authentication
    if current_user and (!current_user.is_master? and !current_user.is_operator?)
      sign_out_and_redirect(current_user)
    end
  end

  helper Bootsy::Engine.helpers  
end
