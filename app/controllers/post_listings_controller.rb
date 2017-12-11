class PostListingsController < ApplicationController
  
  def index
    authorize Post
    #@search = Post.ransack(params[:q]) # moved to ApplicationController
    @posts = @search.result(distinct: true)

    @title = ""
    if params[:channel_slug] && @channel = Channel.find_by_slug(params[:channel_slug])
      @posts = @posts.select{|post| post.channel && post.channel == @channel}
      @title = " in @@" + params[:channel_slug]
    end
    if params[:username] && @author = User.friendly.find(params[:username])
      @posts = @posts.select{|post| post.author && post.author == @author}
      @title = @title + " by @" + params[:username]
    end
    if params[:private]
      @posts = @posts.select{|post| policy(post).list_private?}
      @title = " private posts" + @title
    else
      @posts = @posts.select{|post| policy(post).list?}
      @title = " posts" + @title
    end

    @tag_options = [['With Tag:','']]
    if @channel
      if @author
        for tag, count in tags_tally(@posts)
          @tag_options << [tag.name+" ("+count.to_s+")", channel_author_tag_path(@channel.slug, @author, tag)]
        end
      else
        for tag, count in tags_tally(@posts)
          @tag_options << [tag.name+" ("+count.to_s+")", channel_tag_path(@channel.slug, tag)]
        end
      end
    elsif @author
      for tag, count in tags_tally(@posts)
        @tag_options << [tag.name+" ("+count.to_s+")", author_tag_path(@author, tag)]
      end
    else
      for tag, count in tags_tally(@posts)
        @tag_options << [tag.name+" ("+count.to_s+")", tag_path(tag)]
      end
    end

    if params[:q] && params[:q][:title_or_body_cont]
      @title = @title + ' from search "' + params[:q][:title_or_body_cont] + '"'
    end
    if params[:tag_slug] && @tag = ActsAsTaggableOn::Tag.friendly.find(params[:tag_slug])
      @posts = @posts.select{|post| post.tag_list.include?(@tag.name)}
      @title = @title + " with tag: " + @tag.name
    end

    @posts = @posts.sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @title = @posts_count.to_s + @title
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
      @tag_options << [tag.name+" ("+count.to_s+")", channel_tag_path(@channel,tag)]
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
    @tag   = ActsAsTaggableOn::Tag.friendly.find(params[:tag_slug])
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
  
  private
  
  def tags_tally(posts)
    tags = []
    for post in posts
      for tag in post.tags
        tags << tag
      end
    end
    tallies = tags.group_by{|tag| tag}.map{|k,v| [k,v.length]}.
                   sort{|a,b| [b[1],a[0]] <=> [a[1],b[0]]}
  end
  
end
