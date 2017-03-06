class PostsController < ApplicationController
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default
  before_action :set_post, only: [:show, :edit, :destroy]

  # GET /posts
  # GET /posts.json
  def index
    authorize Post
    @posts = Post.all.select{|post| post.visible > 1 || is_author_or_admin?(current_user, post)}.
             sort_by{|post| post.updated_at}.reverse!
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
    puts @posts
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    authorize @post
    if request.path != post_path(@post.user.username, @post)
      if params[:username].downcase != @post.user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @post.user.username
      elsif request.path.downcase != post_path(@post.user.username, @post).downcase
        flash[:notice] = 'That post has moved to this new URL (probably because title changed).'
      end
      return redirect_back(fallback_location: root_path)
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
    authorize @post
    @body_class = 'grayback'
  end

  # GET /posts/1/edit
  def edit
    authorize @post
    @body_class = 'grayback'
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = current_user.posts.build(post_params)
    authorize @post

    respond_to do |format|
      if @post.save
        AdminMailer.new_post(@post).deliver  # notify admin
        format.html { redirect_to post_path(@post.user.username, @post),
                               notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    @post = Post.find(params[:id])
    authorize @post
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to post_path(@post.user.username, @post),
                               notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    authorize @post
    @post.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = 'Post was successfully destroyed.'
        from_path = Rails.application.routes.recognize_path(request.referrer)
        if from_path[:controller] == 'posts' && from_path[:action] == 'show'
          redirect_to user_path(from_path[:username])
        else
          redirect_back(fallback_location: root_path)
        end
      end
      format.json { head :no_content }
    end
  end
  
  private
    
  def set_post
    if user = User.friendly.find(params[:username])
      @post = Post.where(user_id: user.id).friendly.find(params[:slug])
    else
      @post = Post.find(params[:id])
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(:user_id, :visible, :title, :slug, :body)
  end

  def redirect_to_default
    redirect_to root_path
  end
  
end
