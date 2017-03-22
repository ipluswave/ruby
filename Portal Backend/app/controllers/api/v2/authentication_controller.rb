class Api::V2::AuthenticationController < Api::V2::ApplicationController
  def authenticate
    user = User.find_for_database_authentication(email: params[:email])
    if user and user.valid_password?(params[:password]) and user.has_role? :admin and user.roles.count == 1
      user.update_tracked_fields!(warden.request)
      render json: payload(user)
    else
      render json: {error: 'Invalid Email/Password'}
    end
  end

  private

  def payload(user)
    expiration_ts = ENV['JWT_EXPIRATION_TIMEOUT'].to_i if ENV['JWT_EXPIRATION_TIMEOUT'].present?
    expiration_ts ||= 1800
    {auth_token: JsonWebToken.encode({user_id: user.id, exp: Time.now.to_i + expiration_ts})}
  end
end