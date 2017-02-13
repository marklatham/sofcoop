class UsersController < ApplicationController
  
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    @users = User.all
    authorize User
  end

  def show
    @user = User.find_by_username(params[:username])
    authorize @user
  end

end
