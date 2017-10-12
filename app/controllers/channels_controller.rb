class ChannelsController < ApplicationController
  before_action :set_channel, only: [:show, :posts, :edit, :update, :destroy]

  # Website Home Page
  def home
    @post = Post.find(30) rescue nil
    @standings = Standing.all.order('rank ASC')
    @standings = Kaminari.paginate_array(@standings).page(params[:page])
    @ballot = find_ballot
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

  # GET /@@channel_slug/posts
  def posts
    authorize @channel
    @posts = @channel.posts.select{|post| policy(post).show?}.
             sort_by{|post| post.updated_at}.reverse!
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
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
    if @channel.save
      redirect_to channel_path(@channel.slug), notice: 'Channel was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /channels/1
  def update
    authorize @channel
    if @channel.update(channel_params)
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

  # Use callbacks to share common setup or constraints between actions.
  
  def set_channel
    if @channel = Channel.find_by_slug(params[:channel_slug])
    else
      @channel = Channel.find(params[:id])
    end
  end

  # Only allow a trusted parameter "white list" through.
  def channel_params
    params.require(:channel).permit(:user_id, :name, :slug, :color, :avatar,
                                    :avatar_cache, :color_bg, :dropdown_id)
  end
  
end
