class ImagesController < ApplicationController
  before_action :set_image, only: [:show, :data, :edit, :destroy]

  # GET /images
  def index
    authorize Image
    @images = Image.all.sort_by{|image| image.created_at}.reverse!
    @images = Kaminari.paginate_array(@images).page(params[:page])
  end

  # GET /images
  def user_images
    authorize Image
    @user = User.friendly.find(params[:username])
    @images = @user.images.order('created_at DESC')
    @images = Kaminari.paginate_array(@images).page(params[:page])
    if request.path != user_images_path(@user.username)
      if params[:username].downcase != @user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @user.username
      end
      redirect_to user_images_path(@user.username) and return
    end
  end
  
  # GET /images/1
  def show
    file_url = case params[:version]
      when nil then @image.file_url(:v10)
      when 'v10' then @image.file_url(:v10)
      when 'v3' then @image.file_url(:v3)
      when 'original' then @image.file_url
      else @image.file_url(:v10)
    end
    redirect_to file_url.partition('?').first
  end

  # GET /images/1
  def data
  end

  # GET /images/new
  def new
    @image = Image.new
    authorize @image
    @body_class = 'grayback'
  end

  # GET /images/1/edit
  def edit
    authorize @image
    @body_class = 'grayback'
  end

  # POST /images
  def create
    unless params[:image][:remote_file_url].present? ||
           params[:image][:file].present?
      flash[:error] = 'You need to either upload an image file or paste an image URL.'
      redirect_to new_image_path
      return
    end
    @image = Image.new(image_params)
    authorize @image
    @image.user = current_user
    if @image.save
      redirect_to image_data_path(@image.user.username, @image.slug, @image.format),
                  notice: 'Image was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /images/1
  def update
    @image = Image.find(params[:id])
    authorize @image
    # Move image file to new AWS filename if title changing:
    if image_params[:title]
      unless image_params[:title] == @image.title
        if @image.file.present?
          unless image_params[:file].present?
            unless image_params[:file_cache].present?
              params[:image][:remote_file_url] = @image.file_url.partition('?').first
            end
          end
        end
      end
    end
    if @image.update(image_params)
      redirect_to image_data_path(@image.user.username, @image.slug, @image.format),
                  notice: 'Image was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /images/1
  def destroy
    authorize @image
    @image.destroy
    flash[:notice] = 'Image was successfully destroyed.'
    from_path = Rails.application.routes.recognize_path(request.referrer)
    if from_path[:controller] == 'images' && from_path[:action] == 'data'
      redirect_to user_images_path(from_path[:username])
    else
      redirect_back(fallback_location: root_path)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      if user = User.friendly.find(params[:username])
        @image = Image.where(user_id: user.id).friendly.find(params[:image_slug])
      else
        @image = Image.find(params[:id])
      end
    end

    # Only allow a trusted parameter "white list" through.
    def image_params
      params.require(:image).permit(:title, :slug, :original_filename, :original_url,
      :format, :width, :height, :size, :credit, :description, :file, :file_cache,
      :remote_file_url)
    end

end
