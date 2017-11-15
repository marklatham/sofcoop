class UsersController < ApplicationController
  
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    @users = User.all.page(params[:page])
    authorize User
  end

  def show
    @user = User.friendly.find(params[:username]) if params[:username]
    # "fallback" to find-by-id
    @user = User.find(params[:id]) unless @user
    authorize @user
    @posts = @user.posts.where(category:"post").order('updated_at DESC')
    unless current_user == @user || current_user.is_admin?
      @posts = @posts.select{|post| post.visible > 1}.sort_by{|post| post.updated_at}.reverse!
    end
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
    if request.path != user_path(@user.username)
      if params[:username].downcase != @user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @user.username
      end
      return redirect_to user_path(@user.username)
    end
  end

end
