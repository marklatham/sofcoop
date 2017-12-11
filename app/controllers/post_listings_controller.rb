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
    channel_slug = @channel.slug if @channel
    for tag, count in tags_tally(@posts)
      @tag_options << [tag.name+" ("+count.to_s+")", posts_path(channel_slug, @author, tag)]
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
