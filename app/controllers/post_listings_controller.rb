class PostListingsController < ApplicationController

  def index
    authorize Post
    #@search = Post.ransack(params[:q]) # moved to ApplicationController
    @posts = @search.result(distinct: true)
    
    if params[:private]
      @posts = @posts.select{|post| policy(post).list_private?}
      @title = " private posts"
    else
      @posts = @posts.select{|post| policy(post).list?}
      @title = " posts"
    end
    if params[:username] && @author = User.friendly.find(params[:username])
      @posts = @posts.select{|post| post.author && post.author == @author}
      @title = @title + " by @" + params[:username]
    end

    if params[:channel_slug] && @channel = Channel.find_by_slug(params[:channel_slug])
      @posts = @posts.select{|post| post.channel && post.channel == @channel}
    end
    
    channel_slug = @channel.slug if @channel
    @tag_options = [["any/none (#{@posts.size})", posts_path(channel_slug, @author)]]
    for tag, count in tags_tally(@posts)
      @tag_options << [tag.name+" ("+count.to_s+")", posts_path(channel_slug, @author, tag)]
    end
    
    if params[:q] && params[:q][:title_or_body_cont]
      @title = @title + ' from search "' + params[:q][:title_or_body_cont] + '"'
    end
    @tag_option_selected = ""
    if params[:tag_slug] && @tag = ActsAsTaggableOn::Tag.friendly.find(params[:tag_slug])
      @posts = @posts.select{|post| post.tag_list.include?(@tag.name)}
      @tag_option_selected = posts_path(channel_slug, @author, @tag)
    end
    
    @posts = @posts.sort_by{|post| post.updated_at}.reverse!
    @title = @posts.size.to_s + @title
    @title.sub!("posts", "post") if @posts.size == 1
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def search
    index
    render :index
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
                   sort{|a,b| [b[1],a[0].name] <=> [a[1],b[0].name]}
  end

end
