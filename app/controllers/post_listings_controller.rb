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
    @user = User.friendly.find(params[:username])
    if params[:private]
      @private = params[:private]
      authorize Post    # in post_policy
      authorize @user   # in user_policy
      @posts = @user.posts.where(category:"post").
                           select{|post| policy(post).list_private?}.
                           sort_by{|post| post.updated_at}.reverse!
    else
      if request.path != author_posts_path(@user.username)
        if params[:username].downcase != @user.username.downcase
          flash[:notice] = 'Username @' + params[:username] +
                           ' has changed to @' + @user.username
        end
        return redirect_to author_posts_path(@user.username)
      end
      authorize Post
      @posts = @user.posts.where(category:"post").
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
  
end