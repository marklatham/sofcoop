class PagesController < ApplicationController
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default
  before_action :set_page, only: [:show, :edit, :destroy]

  # GET /pages
  # GET /pages.json
  def index
    authorize Page
    @pages = Page.all.select{|page| page.visible > 1 || is_author_or_admin?(current_user, page)}.
             sort_by{|page| page.updated_at}.reverse!
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    authorize @page
    if request.path != page_path(@page.user.username, @page)
      if params[:username].downcase != @page.user.username.downcase
        flash[:notice] = 'Username @' + params[:username] +
                         ' has changed to @' + @page.user.username
      elsif request.path.downcase != page_path(@page.user.username, @page).downcase
        flash[:notice] = 'That page has moved to this new URL (probably because title changed).'
      end
      return redirect_to page_path(@page.user.username, @page)
    end
  end

  # GET /pages/new
  def new
    @page = Page.new
    authorize @page
    @body_class = 'grayback'
  end

  # GET /pages/1/edit
  def edit
    authorize @page
    @body_class = 'grayback'
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = current_user.pages.build(page_params)
    authorize @page

    respond_to do |format|
      if @page.save
        AdminMailer.new_page(@page).deliver  # notify admin
        format.html { redirect_to page_path(@page.user.username, @page),
                               notice: 'Page was successfully created.' }
        format.json { render :show, status: :created, location: @page }
      else
        format.html { render :new }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pages/1
  # PATCH/PUT /pages/1.json
  def update
    @page = Page.find(params[:id])
    authorize @page
    respond_to do |format|
      if @page.update(page_params)
        format.html { redirect_to page_path(@page.user.username, @page),
                               notice: 'Page was successfully updated.' }
        format.json { render :show, status: :ok, location: @page }
      else
        format.html { render :edit }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    authorize @page
    @page.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = 'Page was successfully destroyed.'
        from_path = Rails.application.routes.recognize_path(request.referrer)
        if from_path[:controller] == 'pages' && from_path[:action] == 'show'
          redirect_to user_path(from_path[:username])
        else
          redirect_back(fallback_location: root_path)
        end
      end
      format.json { head :no_content }
    end
  end
  
  private
    
  def set_page
    if user = User.friendly.find(params[:username])
      @page = Page.where(user_id: user.id).friendly.find(params[:slug])
    else
      @page = Page.find(params[:id])
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def page_params
    params.require(:page).permit(:user_id, :visible, :title, :slug, :body)
  end

  def redirect_to_default
    redirect_to root_path
  end
  
end
