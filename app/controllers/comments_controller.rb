class CommentsController < ApplicationController

  def create
    @comment = current_user.comments.build(comment_params)
    if @comment.author.mod_status == true
      @comment.mod_status = true
    end
    if @comment.save
      flash[:notice] = 'Comment was successfully created.'
      if @comment.mod_status == true
        AdminMailer.moderate_new_comment(@comment, the_comment_url(@comment), current_user).deliver
        flash[:notice] = "Comment is pending moderation. Most users can't see it until it's approved, but they can see you've submitted a comment."
      end
      redirect_to the_comment_path(@comment)
    else
      flash[:notice] = "Error creating comment: #{@comment.errors}"
      redirect_to the_post_path(@comment.post)
    end
  end
  
  def show
    @comment = Comment.find(params[:comment_id])
    authorize @comment
    @post = @comment.post
    @comments = @post.comments.order("created_at DESC")
    count = 0
    for comment in @comments
      count += 1
      break if comment.id == @comment.id
    end
    page = (count-1)/Comment.default_per_page + 1
    page_string = ''
    page_string = '?page='+page.to_s if page > 1
    redirect_to the_post_path(@post)+page_string+'#comment-'+@comment.id.to_s
  end
  
  def edit
    @comment = Comment.find(params[:comment_id])
    authorize @comment
    @post = @comment.post
    comment_edit_path = the_post_path(@post) + "/comment-#{@comment.id.to_s}/edit"
    if request.path != comment_edit_path
      flash[:notice] = 'URL has been auto-corrected.'
      redirect_to comment_edit_path and return
    end
    @comments = @post.comments.order("created_at DESC") # Intentionally not by updated_at.
    if @comment == @comments[0]  # Usual case: editing latest comment.
      @comments = Kaminari.paginate_array(@comments).page(params[:page])
    else
      @comments = [@comment]  # Not worth more coding for this rare case.
    end
    @editing_comment = true
  end
  
  def update
    @comment = Comment.find(params[:id])
    authorize @comment
    @post = @comment.post
    @comment.update(comment_params)
    flash[:notice] = 'Comment updated.'
    redirect_to the_post_path(@post)
  end
  
  def moderate
    authorize Comment
    @comments = Comment.where("mod_status = true").order("created_at DESC")
    @comments = Kaminari.paginate_array(@comments).page(params[:page])
    @title = "Comments Pending Moderation"
  end
  
  def approve
    @comment = Comment.find(params[:comment_id])
    authorize @comment
    @comment.mod_status = false
    @comment.save!
    flash[:notice] = "Comment approved."
    AdminMailer.approved_comment(@comment, the_post_url(@comment.post)+"#comment-#{@comment.id.to_s}", current_user).deliver
    redirect_to the_post_path(@comment.post)
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    redirect_to the_post_path(@comment.post)
  end

  private

  def comment_params
    params.require(:comment).permit(:post_id, :author_id, :body)
  end

end
