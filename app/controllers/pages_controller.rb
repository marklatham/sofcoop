class PagesController < ApplicationController
  
  # Crude fix for problems with def destroy > redirect_to :back :
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_default
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default
  
  before_action :set_page, only: [:show, :edit, :update, :destroy]

  # GET /pages
  # GET /pages.json
  def index
    @pages = Page.all.order('updated_at DESC')
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
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
    @body_class = 'grayback'
    @page = Page.new
  end

  # GET /pages/1/edit
  def edit
    @body_class = 'grayback'
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = current_user.pages.build(page_params)

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
    @page.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Page was successfully destroyed.' }
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
