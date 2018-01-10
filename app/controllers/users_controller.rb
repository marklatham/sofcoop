class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy]
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
    authorize @user
    @posts = @user.posts.where(category:"post").
                         select{|post| policy(post).list?}.
                         sort_by{|post| post.updated_at}.reverse!
    if request.path != user_path(@user.username)
      if params[:username].downcase != @user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @user.username
      end
      redirect_to user_path(@user.username) and return
    end
  end

  def new
    @user = User.new
    authorize @user
    @body_class = 'grayback'
  end
  
  def create
    @user = User.new(permitted_attributes(User))
    authorize @user
    if @user.save
      create_profile_post(@user)
      redirect_to user_path(@user), notice: 'User was successfully created.'
    else
      render :new
    end
  end
  
  def edit
    authorize @user
    @body_class = 'grayback'
  end

  def update
    authorize @user
    # github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    if params[:username]
      # Move avatar file to new AWS filename if username changing:
      unless params[:username] == @user.username
        old_username = @user.username
        if @user.avatar.present?
          unless params[:avatar].present?
            unless params[:avatar_cache].present?
              params[:user][:remote_avatar_url] = @user.avatar_url.partition('?').first
            end
          end
        end
      end
    end
    if @user.update(permitted_attributes(@user))
      @user.save
      redirect_to user_path(@user), notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize @user
    @user.destroy
    redirect_to users_url, notice: 'User was successfully destroyed.'
  end

  private

  def set_user
    if @user = User.find(params[:id]) rescue nil
    else
      @user = User.friendly.find(params[:username])
    end
  end
  
  def create_profile_post(user)
    post = Post.new
    post.author_id = user.id
    post.visible = 0
    post.title = "My Profile"
    post.category = "user_profile"
    post.save
    user.profile_id = post.id
    user.save
  end
  
end
