class UsersController < ApplicationController
  
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    @users = User.all
    authorize User
  end

  def show
    @user = User.friendly.find(params[:username])
    authorize @user
    @pages = @user.pages.order('updated_at DESC')
    unless current_user == @user || current_user.is_admin?
      @pages = @pages.select{|page| page.visible > 1}.sort_by{|page| page.updated_at}.reverse!
    end
    if request.path != user_path(@user.username)
      if params[:username].downcase != @user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @user.username
      end
      return redirect_to user_path(@user.username)
    end
  end

end
