class PostsController < ApplicationController
  before_action :set_post, only: [:show, :markdown, :edit, :destroy]

  def index
    authorize Post
    #@search = Post.ransack(params[:q]) # moved to ApplicationController
    @posts = @search.result(distinct: true).select{|post| policy(post).list?}.
                                            sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def search
    index
    render :index
  end

  def user_posts
    @user = User.friendly.find(params[:username])
    if request.path != user_posts_path(@user.username)
      if params[:username].downcase != @user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @user.username
      end
      return redirect_to user_posts_path(@user.username)
    end
    authorize Post
    @posts = @user.posts.where(category:"post").select{|post| policy(post).list?}.
                                                sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end
  
  def show
    if params[:username] && request.path != the_post_path(@post)
      if params[:username].downcase != @post.author.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @post.author.username
      elsif params[:slug].downcase != @post.slug.downcase
        flash[:notice] = 'That post has changed its title and URL.'
      else
        flash[:notice] = 'That post is now at this URL.'
      end
      return redirect_to the_post_path(@post)
    end
    authorize @post
    @comment = Comment.new(post: @post)
  end
  
  def markdown
    authorize @post
  end

  def new
    @post = Post.new
    authorize @post
    @body_class = 'grayback'
  end

  def edit
    authorize @post
    @body_class = 'grayback'
  end

  def create
    @post = current_user.posts.build(post_params)
    authorize @post
    body_before = ''
    body_before << @post.body
    body_array = @post.body.split("\n")
    puts "BODY_ARRAY:"
    puts body_array
    post_body = process_images(@post.body, body_array)
    body_array = post_body.split("\n")
    @post.body, admin_email = process_channel_links(post_body, body_array)
    @post.main_image = first_image(@post.body)
    if @post.save
      AdminMailer.new_post(@post, the_post_url(@post)).deliver  # notify admin
      if @post.channel
        AdminMailer.post_assigned(@post, @post.channel, current_user).deliver
      end
      if admin_email.present?
        AdminMailer.post_process(admin_email, @post, the_post_url(@post), body_before, @post.body, 'created').deliver
      end
      if params[:commit] == 'Save & edit more'
        redirect_to edit_post_path(@post.author.username, @post.slug) and return
      else # Should be the only other case: params[:commit] == 'Save & see post'
        redirect_to the_post_path(@post) and return
      end
    else
      render :new
    end
  end

  def update
    @post = Post.find(params[:id])
    authorize @post
    body_before = ''
    body_before << post_params[:body]   # Don't know why, but body_before = post_params[:body] fails.
    new_lines = []
    for line in Diffy::Diff.new(@post.body, post_params[:body])
      new_lines << line.from(1) if /^\+/.match(line)
    end
    puts "NL FOR IMAGES:"
    puts new_lines
    post_body = process_images(post_params[:body], new_lines)
    new_lines = []
    for line in Diffy::Diff.new(@post.body, post_body)
      new_lines << line.from(1) if /^\+/.match(line)
    end
    puts "NL FOR CHLINKS:"
    puts new_lines
    body_after, admin_email = process_channel_links(post_body, new_lines)
    if admin_email.present?
      AdminMailer.post_process(admin_email, @post, the_post_url(@post), body_before, body_after, 'edited').deliver
    end
    params[:post][:body] = body_after
    params[:post][:main_image] = first_image(params[:post][:body])
    old_channel = @post.channel if @post.channel
    if @post.update(post_params)
      flash[:notice] = 'Post saved.'
      unless old_channel && @post.channel == old_channel
        if @post.channel
          unless @post.channel.manager == current_user && @post.author == current_user
            AdminMailer.post_assigned(@post, @post.channel, current_user).deliver
          end
        end
      end
      unless @post.channel && @post.channel == old_channel
        if old_channel
          unless old_channel.manager == current_user && @post.author == current_user
            AdminMailer.post_unassigned(@post, old_channel, current_user).deliver
          end
        end
      end
      if params[:commit] == 'Save & edit more'
        redirect_to edit_post_path(@post.author.username, @post.slug) and return
      else # Should be the only other cases: params[:commit] == 'Save & see post/profile'
        redirect_to the_post_path(@post) and return
      end
    else
      render :edit 
    end
  end

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
    if params[:username]
      user = User.friendly.find(params[:username])
      @post = Post.where(author_id: user.id).friendly.find(params[:slug])
    elsif params[:id]
      @post = Post.find(params[:id])
    elsif params[:vanity_slug]
      if post_id = vanity_slugs.key(params[:vanity_slug])
        @post = Post.find(post_id)
      else
        @post = Post.find(27)  # "Page Not Found"
      end
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(:author_id, :visible, :title, :slug, :body,
        :main_image, :main_image_cache, :remote_main_image_url, :tag_list,
        :channel_id, :category)
  end

  def process_images(input_body, new_lines)
    flash[:process] = []
    processed_body = input_body
    for new_line in new_lines
      # puts "NEW LINE: " + new_line
      remainder = new_line
      while remainder.size > 0 do
        substrings = remainder.partition('![')        # Find next old_image_string.
        break unless substrings[2].present?           # No more image(s) in this line.
      
        remainder = substrings[2]    # If all checks below fail, resume processing here.
      
        old_image_string = ''
        old_image_string << '[' if substrings[0].last == '['  # Does it have a web link?
        old_image_string << '!['
        
        substrings = substrings[2].partition('](')
        unless substrings[2].present?
          flash[:process] << "Strange: couldn't find image link after " +
                             old_image_string + substrings[0]
          break                                       # No more image(s) in this line.
        end
        title = substrings[0]
        old_image_string << substrings[0] + ']('
      
        if old_image_string.first == '['                      # Does it have a web link?
          substrings = substrings[2].partition(')](')
          unless substrings[2].present?
            flash[:process] << "Strange: couldn't find image web link after " +
                               old_image_string + substrings[0]
            next
          end
          old_image_string << substrings[0] + ')]('
        end
      
        substrings = substrings[2].partition(')')
        unless substrings[1].present?
          flash[:process] << "Strange: couldn't find ) after image string " +
                             old_image_string + substrings[0]
          next
        end
        old_image_string << substrings[0] + ')'
      
        remainder = substrings[2]
        new_image_string = process_an_image(old_image_string, title)
        if new_image_string != old_image_string
          processed_body.gsub!(old_image_string, new_image_string)
        end
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

  # Append channel-color CSS style to links leading to channel:
  def process_channel_links(input_body, new_lines)
    flash[:process] = []
    admin_email = []
    # admin_email << 'NEW LINES:'
    # for new_line in new_lines
    #   admin_email << new_line
    # end
    
    processed_body = input_body
    for new_line in new_lines
      remainder = new_line
      while remainder.size > 0 do
        substrings = remainder.partition('/@@')          # Find next channel link?
        break unless substrings[2].present?
        remainder = substrings[2]
        new_channel_link = '](/@@'
        if substrings[0].end_with? ']('
          old_channel_link = '](/@@'
        elsif substrings[0].end_with? '](https://sofcoop.org'
          old_channel_link = '](https://sofcoop.org/@@'
        elsif substrings[0].end_with? '](http://sofcoop.org'
          old_channel_link = '](http://sofcoop.org/@@'
        elsif substrings[0].end_with? '](http://localhost:3000'
          old_channel_link = '](http://localhost:3000/@@'
        else
          admin_email << 'Warning: Strange string at: ' + substrings[0].last(6) + '/@@'
          next                                           # Not a channel link.
        end
      
        substrings = remainder.partition('/')            # Find end of channel slug??
        break unless substrings[2].present?
        remainder = substrings[2]
        if channel = Channel.find_by(slug: substrings[0]) rescue nil
          # continue
        else
          admin_email << 'Warning: No channel found for @@' + substrings[0]
          next
        end
        # admin_email << 'CHANNEL: ' + channel.slug
        
        old_channel_link << substrings[0] + '/'
        new_channel_link << substrings[0] + '/'
      
        substrings = remainder.partition(')')            # Find end of channel link??
        break unless substrings[1].present?
        remainder = substrings[2]
        old_channel_link << substrings[0] + ')'
        new_channel_link << substrings[0] + ')'
      
        tag = '{: .color-' + channel.slug + '}'
        # admin_email << 'REMAINDER AFTER LINK: '
        # admin_email << remainder
        next if remainder.start_with? tag            # Already tagged.
        new_channel_link << tag                      # Else tag it.
      
        identifier = remainder.first(tag.size).partition("\n")[0]
        # puts "IDENTIFIER: "
        # puts identifier
        # p identifier
      
        if remainder.start_with? '{: .color-'        # Wrong color tag?
          substrings = remainder.partition('}')      # Investigate...
        #   admin_email << 'substrings[0]: '
        #   admin_email << substrings[0]
          if substrings[1].present?
            old_channel_link << substrings[0] + substrings[1]  # Replace erroneous tag.
            admin_email << 'Warning: Replacing erroneous tag in: ' + old_channel_link
            identifier = ''
          else
            admin_email << 'Warning: Leaving strange string after: ' + new_channel_link
            admin_email << 'That strange string is: {' + substrings[0].partition("\n")[0]
          end
        end
        old_channel_link = old_channel_link + identifier # So gsub won't double-tag other links.
        new_channel_link = new_channel_link + identifier
        # admin_email << 'IDENTIFIER: ' + identifier
        # admin_email << 'OLD LINK: ' + old_channel_link
        # admin_email << 'NEW LINK: ' + new_channel_link
        if new_channel_link != old_channel_link
          processed_body.gsub!(old_channel_link, new_channel_link)
        end
      end
    end
    return [processed_body, admin_email]
  end
  
end
