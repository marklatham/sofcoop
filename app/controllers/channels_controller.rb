class ChannelsController < ApplicationController
  before_action :set_channel, only: [:show, :edit, :update, :destroy]

  # GET /channels
  def index
    authorize Channel
    @channels = Channel.all
  end

  # GET /channels/1
  def show
    authorize @channel
  end

  # GET /channels/new
  def new
    @channel = Channel.new
    authorize @channel
  end

  # GET /channels/1/edit
  def edit
    authorize @channel
  end

  # POST /channels
  def create
    @channel = Channel.new(channel_params)
    authorize @channel

    if @channel.save
      redirect_to @channel, notice: 'Channel was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /channels/1
  def update
    authorize @channel
    if @channel.update(channel_params)
      redirect_to @channel, notice: 'Channel was successfully updated.'
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
      @channel = Channel.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def channel_params
      params.require(:channel).permit(:user_id, :name, :slug, :color, :avatar)
    end
end
