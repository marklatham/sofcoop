class ImagesController < ApplicationController
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default
  before_action :set_image, only: [:show, :data, :edit, :destroy]

  # GET /images
  def index
    authorize Image
    @images = Image.all.sort_by{|image| image.created_at}.reverse!
    @images = Kaminari.paginate_array(@images).page(params[:page])
  end

  # GET /images/1
  def show
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
    redirect_to images_url, notice: 'Image was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      if user = User.friendly.find(params[:username])
        @image = Image.where(user_id: user.id).friendly.find(params[:slug])
      else
        @image = Image.find(params[:id])
      end
    end

    # Only allow a trusted parameter "white list" through.
    def image_params
      params.require(:image).permit(:title, :slug, :original_filename, :original_url, :format, :width, :height, :size, :description, :file, :file_cache, :remote_file_url)
    end

    def redirect_to_default
      redirect_to root_path
    end
    
end
