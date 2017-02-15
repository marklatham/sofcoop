class PagesController < ApplicationController
  before_action :set_page, only: [:show, :edit, :update, :destroy]

  # GET /pages
  # GET /pages.json
  def index
    @pages = Page.all
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
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
        format.html { redirect_to userpage_path(@page), notice: 'Page was successfully created.' }
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
        format.html { redirect_to userpage_path(@page), notice: 'Page was successfully updated.' }
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
      format.html { redirect_to pages_url, notice: 'Page was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    
    def userpage_path(page)
      '/@' + page.user.username + '/' + page.slug
    end
    
    def set_page
      if user = User.find_by_username(params[:username])
        @page = Page.where(user_id: user.id).friendly.find(params[:slug])
      else
        @page = Page.find(params[:id])
      end
      if request.path != userpage_path(@page)
        return redirect_to userpage_path(@page), notice: 'That page has moved to this new URL (probably because title changed).'
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def page_params
      params.require(:page).permit(:user_id, :visible, :title, :slug, :body)
    end
end
