class Api::V2::UsersController < Api::V2::BaseController

  swagger_controller :users, "Users"

  swagger_api :index do |api|
    summary "Fetches all User items"
    Api::V2::BaseController::add_common_params(api)
    Api::V2::BaseController::add_page_params(api)
    response :unauthorized
    response :not_acceptable
    response :requested_range_not_satisfiable
  end

  def index
    @users = @organization.users
    if params[:page].present? && params[:page].to_i > 0 && params[:page_size].present? && params[:page_size].to_i > 0
      @users = @users.drop(params[:page_size].to_i * (params[:page].to_i - 1)).first(params[:page_size].to_i)
    end
    @users
  end

  swagger_api :show do |api|
    summary "Fetches a single User item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "User ID"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  def show
    @user = @organization.users.find_by(id: params[:id])
    unless @user.present?
      render json: {error: 'User not found'}, :status => 404
    end
  end

  swagger_api :create do |api|
    summary "Creates a new User"
    Api::V2::BaseController::add_common_params(api)
    api.param :form, "user[email]", :string, :required, "Email"
    api.param :form, "user[password]", :string, :required, "Password"
    api.param :form, "user[settings]", :string, :optional, "Settings"
    response :unauthorized
    response :not_acceptable
  end

  def create
    @user = @organization.users.new(user_params.merge({pin: [*(0..9)].sample(4).join}))
    @user.add_role(:admin)
    unless @user.save
      render :json => {error: @user.errors.full_messages}, :status => 400
      return
    end
    @user
  end

  swagger_api :update do |api|
    summary "Updates an existing User"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "User ID"
    api.param :form, "user[email]", :string, :optional, "Email"
    api.param :form, "user[settings]", :string, :optional, "Settings"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  def update
    @user = @organization.users.find_by(id: params[:id])
    unless @user.present?
      render json: {error: 'User not found'}, :status => 404
    end
    unless @user.update_attributes(user_params)
      render :json => {error: @user.errors.full_messages}, :status => 400
      return
    end
    @user
  end

  swagger_api :destroy do |api|
    summary "Deletes an existing User item"
    Api::V2::BaseController::add_common_params(api)
    api.param :path, :id, :integer, :required, "User ID"
    response :unauthorized
    response :not_found
  end

  def destroy
    @user = @organization.users.find_by(id: params[:id])
    unless @user.present?
      render json: {error: 'User not found'}, :status => 404
    end
    @user.destroy
    render :json => {result: "Success"}, :status => 200
  end
  
  def me
    @me = current_user
  end

  def password_reset
    if !params[:user].present? || !params[:user][:email].present?
      render json: {error: 'Required parameters were not passed'}, :status => 400
      return
    end
    user = User.find_for_database_authentication(email: params[:user][:email])
    if !user || !(user.has_role? :admin)
      render json: {error: 'User not found'}, :status => 404
      return
    end
    user.send_reset_password_instructions
    render :json => {result: "Success"}, :status => 200
  end

  def password_new
    if !params[:user].present? || !params[:user][:password].present? || !params[:user][:password_confirmation].present?
      render json: {error: 'Required parameters were not passed'}, :status => 400
      return
    end
    errors = User.reset_password_by_token(params[:user]).errors
    if errors.present?
      render :json => {error: errors.full_messages}, :status => 400
      return
    end
    render :json => {result: "Success"}, :status => 200
  end

  private

  def user_params
    permitted = params[:user].present? ? params.require(:user).permit(:email, :password, :settings) : {}
  end

end