class UsersController < ApplicationController
  
  after_action :verify_authorized  # pundit gem

  def index
    authorize User
    @users = User.all.select{|user| policy(user).show?}.sort_by{|user| user.username}
    @users_count = @users.size
    @users = Kaminari.paginate_array(@users).page(params[:page])
    if current_user
      if current_user.is_admin?
        @viewers = "admin (i.e. all users!)"
      elsif current_user.is_member?
        @viewers = "members (also your own profile)"
      else
        @viewers = "people logged in (also your own profile)"
      end
    else
      @viewers = "everyone including those not logged in"
    end
  end

  def show
    @user = User.friendly.find(params[:username]) if params[:username]
    # fallback - find-by-id:
    @user = User.find(params[:id]) unless @user
    authorize @user
    @posts = @user.posts.select{|post| policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
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
