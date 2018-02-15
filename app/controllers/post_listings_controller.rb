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
    title_or_body_cont = nil
    if params[:q] && params[:q][:title_or_body_cont]
      title_or_body_cont = params[:q][:title_or_body_cont]
      @title = @title + ' from search "' + params[:q][:title_or_body_cont] + '"'
    end
    
    channels_tally, posts_count_prechannel = channels_tally(@posts, params[:tag_slug])

    if params[:channel_slug] && @channel = Channel.find_by_slug(params[:channel_slug])
      @posts = @posts.select{|post| post.channel && post.channel == @channel}
      @channel_option_selected =
                    list_posts_path(params[:channel_slug], @author, @tag, title_or_body_cont)
    end
    
    channel_slug = @channel.slug if @channel
    @tag_options = [["any/none (#{@posts.size})",
                     list_posts_path(channel_slug, @author, nil, title_or_body_cont)]]
    tags_tally = tags_tally(@posts)
    tags_tally = tags_tally[0..19]
    for tag, count in tags_tally
      @tag_options << [tag.name+" ("+count.to_s+")",
                       list_posts_path(channel_slug, @author, tag, title_or_body_cont)]
    end
    
    @tag_option_selected = ""
    if params[:tag_slug] && @tag = ActsAsTaggableOn::Tag.friendly.find(params[:tag_slug])
      @posts = @posts.select{|post| post.tag_list.include?(@tag.name)}
      @tag_option_selected = list_posts_path(channel_slug, @author, @tag, title_or_body_cont)
    end

    @channel_options = [["any/none (#{posts_count_prechannel})",
                         list_posts_path(nil, @author, @tag, title_or_body_cont)]]
    for channel, count in channels_tally
      count = 0 unless count
      @channel_options << [channel.name+" ("+count.to_s+")",
                           list_posts_path(channel.slug, @author, @tag, title_or_body_cont)]
    end
    
    @posts = @posts.sort_by{|post| post.updated_at}.reverse!
    @title = @posts.size.to_s + @title
    @title.sub!("posts", "post") if @posts.size == 1
    @arrays = []
    for post in @posts
      @arrays << [post, nil]
    end
    @arrays = Kaminari.paginate_array(@arrays).page(params[:page])
  end

  def search
    index
    render :index
  end
  
  def history
    set_post
    authorize @post
    @versions = PaperTrail::Version.where("item_type = ? AND item_id = ? AND item_version_id >= 0",
                                                  "Post",       @post.id).order("created_at")
    @arrays = []
    updater = @post.author  # Default in case not found below.
    updater = User.find(@versions[0].whodunnit)
    for version in @versions
      if version.event == "create"
        # No version.object.
        next
      elsif version.event == ( "update-mod" || "update-modded" )
        # whodunnit field is updater who created THIS version.object:
        post = version.reify
        updater = post.author  # Default in case not found below.
        updater = User.find(version.whodunnit)
        @arrays << [post, version, updater]
      else
        # whodunnit field is updater who created version.object NEXT TIME in this fork:
        post = version.reify
        @arrays << [post, version, updater]
        updater = post.author  # Default in case not found below.
        updater = User.find(version.whodunnit)
      end
    end
    # Updater of live post. BTW = moderator if post was just approved:
    @arrays << [@post, nil, updater]
    @arrays = @arrays.sort_by{|array| array[0].updated_at}.reverse!
    @arrays = Kaminari.paginate_array(@arrays).page(params[:page])
  end
  
  def moderate
    authorize Post
    versions = PaperTrail::Version.where("item_type = ? AND event = ?", "Post", "update-mod")
    posts = Post.where("category = ?", "post_mod")
    arrays = []
    for version in versions
      arrays << [nil, version, version.item_id, version.created_at]
    end
    for post in posts
      arrays << [post, nil, post.id, post.updated_at]
    end
    groups = arrays.group_by{|array| array[2]}
    arrays = []
    for id, group in groups
      arrays << group.max_by(&:last)
    end
    arrays = arrays.sort_by(&:last).reverse!
    @arrays = []
    for post, version, id, date in arrays
      post = version.reify if version
      @arrays << [post, version]
    end
    @arrays = Kaminari.paginate_array(@arrays).page(params[:page])
    @title = "Posts Pending Moderation"
  end

  private
  
  def list_posts_path(channel_slug, author, tag, title_or_body_cont)
    path = posts_path(channel_slug, author, tag)
    if title_or_body_cont.present?
      path + "/search?q[title_or_body_cont]=" + title_or_body_cont
    else
      path
    end
  end
  
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
  
  def channels_tally(posts, tag_slug)

    if tag_slug && @tag = ActsAsTaggableOn::Tag.friendly.find(tag_slug)
      posts = posts.select{|post| post.tag_list.include?(@tag.name)}
    end
    
    if nav_channels.size < 21
      channels = nav_channels
    else
      channels = nav_channels[0..19]
    end
    
    tally = []
    for channel in channels
      tally << [channel, 0]
    end
    
    for post in posts
      if post.channel
        for entry in tally
          if post.channel == entry[0]
            entry[1] += 1
            break
          end
        end
      end
    end
    
    return [tally, posts.size]
  end

  def set_post  # Copied from posts_controller. TO DO: DRY.
    if params[:username]
      user = User.friendly.find(params[:username])
      @post = Post.where(author_id: user.id).friendly.find(params[:post_slug])
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
  
end
