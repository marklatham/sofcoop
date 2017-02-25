class UsersController < ApplicationController
  
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    @users = User.all
    authorize User
  end

  def show
    @user = User.find_by_username(params[:username])
    @pages = Page.where(user_id: @user.id).order('updated_at DESC')
    authorize @user
  end

end
