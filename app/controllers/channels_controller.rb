class ChannelsController < ApplicationController
  before_action :set_channel, only: [:past_shares1, :show, :edit, :update, :destroy]

  # Website Home Page
  def home
    @post = Post.where(category: "home_page").first rescue nil
    @standings = Standing.all.order('rank ASC')
    @standings = Kaminari.paginate_array(@standings).page(params[:page])
    @ballot = find_ballot
  end

  # History of award shares & rankings
  # For all channels:
  def past_shares
    @past_standings = PastStanding.all.order("tallied_at DESC, rank ASC")
    finalists = []
    for past_standing in @past_standings
      finalists << past_standing
      break if finalists.size > 5 and past_standing.share < 0.00001
      break if past_standing.tallied_at < @past_standings[0].tallied_at
    end
    @channel_ids = finalists.map(&:channel_id).uniq
  end
  # For one channel:
  def past_shares1
    @past_standings = @channel.past_standings.order("tallied_at DESC")
    @past_standings = Kaminari.paginate_array(@past_standings).page(params[:page]).per(20)
  end
  
  # GET /channels
  def index
    authorize Channel
    @channels = Channel.all
  end

  # GET /@@channel_slug
  def show
    authorize @channel
  end

  # GET /channels/new
  def new
    @channel = Channel.new
    authorize @channel
    @body_class = 'grayback'
  end

  # GET /channels/1/edit
  def edit
    authorize @channel
    @body_class = 'grayback'
  end

  # POST /channels
  def create
    @channel = Channel.new(channel_params)
    authorize @channel
    @channel.manager_id ||= current_user.id
    if @channel.save
      create_standing(@channel)
      create_profile_posts(@channel)
      redirect_to channel_path(@channel.slug), notice: 'Channel was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /channels/1
  def update
    authorize @channel
    if @channel.update(channel_params)
      unless @channel.manager_id
        @channel.manager_id = current_user.id
        @channel.save
      end
      redirect_to channel_path(@channel.slug), notice: 'Channel was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /channels/1
  def destroy
    authorize @channel
    @channel.destroy
    redirect_to channels_url, notice: 'Channel was successfully destroyed.'
  end

  private

  def set_channel
    if @channel = Channel.find_by_slug(params[:channel_slug]) rescue nil
    else
      @channel = Channel.find(params[:id])
    end
  end
  
  def create_standing(channel)
    last = Standing.all.order("rank ASC").last
    standing = Standing.new
    standing.channel_id = channel.id
    standing.rank = last.rank + 1
    standing.share = 0
    standing.count0 = 0
    standing.count1 = 0
    standing.tallied_at = last.tallied_at
    standing.save
  end
  
  def create_profile_posts(channel)
    post = Post.new
    post.author_id = channel.manager.id
    post.visible = 4
    post.title = "#{channel.name} Channel Profile"
    post.channel_id = channel.id
    post.category = "channel_profile"
    post.save
    channel.profile_id = post.id
    post = Post.new
    post.author_id = channel.manager.id
    post.visible = 4
    post.title = "#{channel.name} Channel Dropdown"
    post.channel_id = channel.id
    post.category = "channel_dropdown"
    post.save
    channel.dropdown_id = post.id
    channel.save
  end
  
  # Only allow a trusted parameter "white list" through.
  def channel_params
    params.require(:channel).permit(:manager_id, :name, :slug, :color, :avatar,
                            :avatar_cache, :color_bg, :dropdown_id, :profile_id)
  end
  
end
