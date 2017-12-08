class PostListingsController < ApplicationController
  
  def index
    authorize Post
    #@search = Post.ransack(params[:q]) # moved to ApplicationController
    @posts = @search.result(distinct: true).select{|post| policy(post).list?}.
                                            sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @tag_options = [['With Tag:','']]
    for tag, count in tags_tally(@posts)
      @tag_options << [tag.name+" ("+count.to_s+")", tag_path(tag.slug)]
    end
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def search
    index
    render :index
  end

  # GET /@@channel_slug/posts
  def channel_posts
    @channel = Channel.find_by_slug(params[:channel_slug])
    authorize @channel
    @posts = @channel.posts.select{|post| policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
    @tag_options = [['With Tag:','']]
    for tag, count in tags_tally(@posts)
      @tag_options << [tag.name+" ("+count.to_s+")", channel_tag_path(@channel.slug,tag.slug)]
    end
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end
  
  def author_posts
    @author = User.friendly.find(params[:username])
    if params[:private]
      authorize Post    # in post_policy
      authorize @author   # in user_policy
      @posts = @author.posts.where(category:"post").
                           select{|post| policy(post).list_private?}.
                           sort_by{|post| post.updated_at}.reverse!
    else
      if request.path != author_posts_path(@author)
        if params[:username].downcase != @author.username.downcase
          flash[:notice] = 'Username @' + params[:username] +
                           ' has changed to @' + @author.username
        end
        return redirect_to author_posts_path(@author)
      end
      authorize Post
      @posts = @author.posts.where(category:"post").
                           select{|post| policy(post).list?}.
                           sort_by{|post| post.updated_at}.reverse!
    end
    @posts_count = @posts.size
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  # GET /@@channel_slug/posts
  def channel_author
    @channel = Channel.find_by_slug(params[:channel_slug])
    @author = User.friendly.find(params[:username])
    authorize @channel
    authorize @author
    @posts = @channel.posts.select{|post| post.author == @author && policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
    @tag_options = [['With Tag:','']]
    for tag, count in tags_tally(@posts)
      @tag_options << [tag.name+" ("+count.to_s+")", channel_tag_path(@channel.slug,tag.slug)]
    end
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def tag_posts
    @tag   = ActsAsTaggableOn::Tag.friendly.find(params[:slug])
    @posts = Post.tagged_with(@tag.name).select{|post| policy(post).list?}
    if params[:channel_slug] && @channel = Channel.find_by_slug(params[:channel_slug])
      @posts = @posts.select{|post| post.channel && post.channel == @channel}
    end
    if params[:username] && @author = User.friendly.find(params[:username])
      @posts = @posts.select{|post| post.author && post.author == @author}
    end
    @posts = @posts.sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end
  
end
