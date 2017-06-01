class PostsController < ApplicationController
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default
  before_action :set_post, only: [:show, :edit, :destroy]

  # GET /posts
  def index
    authorize Post
    #@search = Post.ransack(params[:q]) # moved to ApplicationController
    @posts = @search.result(distinct: true).select{|post| policy(post).show?}.
             sort_by{|post| post.updated_at}.reverse!
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def search
    index
    render :index
  end

  # GET /images
  def user_posts
    authorize Post
    @user = User.friendly.find(params[:username])
    @posts = @user.posts.order('updated_at DESC')
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
    if request.path != user_posts_path(@user.username)
      if params[:username].downcase != @user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @user.username
      end
      return redirect_to user_posts_path(@user.username)
    end
  end
  
  # GET /posts/1
  def show
    authorize @post
    @comment = Comment.new(post: @post)
    if request.path != post_path(@post.user.username, @post.slug)
      if params[:username].downcase != @post.user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @post.user.username
      elsif request.path.downcase != post_path(@post.user.username, @post.slug).downcase
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
  def create
    @post = current_user.posts.build(post_params)
    authorize @post
    @post.body = process_images(@post.body, @post.body)
    @post.main_image = first_image(@post.body)
    if @post.save
      AdminMailer.new_post(@post).deliver  # notify admin
      redirect_to post_path(@post.user.username, @post.slug),
                  notice: 'Post was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /posts/1
  def update
    @post = Post.find(params[:id])
    authorize @post
    new_lines = ''
    Diffy::Diff.new(@post.body, post_params[:body]).each do |line|
      new_lines << line if /^\+/.match(line)
    end
    params[:post][:body] = process_images(post_params[:body], new_lines)
    params[:post][:main_image] = first_image(params[:post][:body])
    if @post.update(post_params)
      flash[:notice] = 'Post saved.'
      if params[:commit] == 'Save & edit more'
        redirect_to edit_post_path(@post.user.username, @post.slug) and return
      else # Should be the only other case: params[:commit] == 'Save & see post'
        redirect_to post_path(@post.user.username, @post.slug) and return
      end
    else
      render :edit 
    end
  end

  # DELETE /posts/1
  def destroy
    authorize @post
    @post.destroy
    flash[:notice] = 'Post was successfully destroyed.'
    from_path = Rails.application.routes.recognize_path(request.referrer)
    if from_path[:controller] == 'posts' && from_path[:action] == 'show'
      redirect_to user_path(from_path[:username])
    else
      redirect_back(fallback_location: root_path)
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
    params.require(:post).permit(:user_id, :visible, :title, :slug, :body,
        :main_image, :main_image_cache, :remote_main_image_url, :tag_list, :channel_id)
  end

  def redirect_to_default
    redirect_to root_path
  end
  
  def process_images(input_body, new_lines)
    processed_body = input_body
    remainder = new_lines
    flash[:process] = []
    while remainder.size > 0 do
      substrings = remainder.partition('![')                # Find next old_image_string.
      return processed_body unless substrings[2].present?
      
      old_image_string = ''
      old_image_string << '[' if substrings[0].last == '['  # Does it have a web link?
      old_image_string << '!['
        
      substrings = substrings[2].partition('](')
      unless substrings[2].present?
        flash[:process] << "Strange: couldn't find image link after " +
                           old_image_string + substrings[0]
        return processed_body
      end
      title = substrings[0]
      old_image_string << substrings[0] + ']('
      
      if old_image_string.first == '['                      # Does it have a web link?
        substrings = substrings[2].partition(')](')
        unless substrings[2].present?
          flash[:process] << "Strange: couldn't find image web link after " +
                             old_image_string + substrings[0]
          return processed_body
        end
        old_image_string << substrings[0] + ')]('
      end
      
      substrings = substrings[2].partition(')')
      unless substrings[1].present?
        flash[:process] << "Strange: couldn't find ) after image string " +
                           old_image_string + substrings[0]
        return processed_body
      end
      old_image_string << substrings[0] + ')'
      
      remainder = substrings[2]
      new_image_string = process_an_image(old_image_string, title)
      if new_image_string != old_image_string
        processed_body.gsub!(old_image_string, new_image_string)
      end
    end
    return processed_body
  end
  
  def process_an_image(old_image_string, title)
    
    if old_image_string.first == '['                       # ...then strip off the web link:
      old_image_string = old_image_string[1..-1].partition(')](')[0] + ')'
    end
    
    old_image_path = old_image_string.partition('![')[2].partition('](')[2].partition(')')[0].partition(' ')[0]
    
    unless ['jpg', 'jpeg', 'gif', 'png'].include? old_image_path.partition('?')[0].split('.').last
      flash[:process] <<
      'Image file format must be jpg or jpeg or gif or png, but file is ' + old_image_path
      return old_image_string
    end
    
    # Does old_image_string point to our database?
    test_path = nil
    if old_image_path.first(9) == '/images/@'
      test_path = old_image_path.from(9)
    elsif old_image_path.first(8) == 'images/@'
      test_path = old_image_path.from(8)
    elsif old_image_path.include? 'sofcoop.org/images/@'
      test_path = old_image_path.partition('sofcoop.org/images/@')[2]
    elsif old_image_path.include? 'localhost:3000/images/@'
      test_path = old_image_path.partition('localhost:3000/images/@')[2]
    elsif old_image_path.include? 'sofcoop.s3'
      test_path = old_image_path.partition('sofcoop.s3')[2].partition('/images/')[2]
    end
    
    # If so, then look it up in our database to make sure:
    if test_path
      substrings = test_path.partition('/')
      if substrings[2].present?
        puts 'substrings[0]: ' + substrings[0]
        if user = User.friendly.find(substrings[0]) rescue nil
          substrings = substrings[2].split('.')
          slug = substrings[0]
          puts 'slug: ' + slug
          version = nil
          if substrings[2].present?
            version = substrings[1]
            puts 'version: ' + version
          end
          if image = Image.where(user_id: user.id).friendly.find(slug) rescue nil
            new_image_path = image_path(image.user.username, image.slug, version, image.format)
            unless new_image_path == old_image_path
              flash[:process] << 'Updated image path from: ' + old_image_path
              flash[:process] << '... to: ' + new_image_path
            end
            new_image_string = old_image_string.gsub(old_image_path, new_image_path)
            new_image_string = '[' + new_image_string + '](' +
              image_data_path(image.user.username, image.slug, image.format) + ')'
            return new_image_string
          end
        end
      end
      flash[:process] <<
      'Image path points to our database but image not found: ' + old_image_string
      return old_image_string
    end
    
    # For remote image paths, make sure they start with http
    if old_image_path.first(4) == 'http'
      test_path = old_image_path
    else
      test_path = 'http://' + old_image_path
    end
    
    # Download & store remote image:
    response = HTTParty.get(test_path)
    if response.code == 200 && response.headers['Content-Type'].start_with?('image')
      image_params = {remote_file_url: test_path, title: title, description: ''}
      image = Image.new(image_params)
      image.user = current_user
      if image.save
        new_image_path = image_path(image.user.username, image.slug, version, image.format)
        flash[:process] << old_image_path + ' saved as ' + new_image_path
        new_image_string = old_image_string.gsub(old_image_path, new_image_path)
        new_image_string = '[' + new_image_string + '](' +
          image_data_path(image.user.username, image.slug, image.format) + ')'
        return new_image_string
      else
        flash[:process] << 'Tried to store ' + old_image_string +
                           ' locally but failed, so linking to it remotely.'
      end
    end
    puts 'Could not find image: ' + old_image_string
    return old_image_string
  end

  # Get URL of first image in post.body markdown text:
  def first_image(text)
    path = text.partition('![')[2].partition('](')[2].partition(')')[0] rescue nil
    if path.first(9) == '/images/@'
      substrings = path.split('.')
      if substrings[2].present?
        substrings[0] + '.v3.' + substrings[2] rescue nil
      else
        substrings[0] + '.v3.' + substrings[1] rescue nil
      end
    else
      nil
    end
  end

end
