class CommentsController < ApplicationController

  def create
    @comment = current_user.comments.build(comment_params)
    if @comment.save
      flash[:notice] = 'Comment was successfully created.'
      redirect_to the_post_path(@comment.post)
    else
      flash[:notice] = "Error creating comment: #{@comment.errors}"
      redirect_to the_post_path(@comment.post)
    end
  end
  
  def edit
    @comment = Comment.find(params[:comment_id])
    authorize @comment
    @post = @comment.post
    comment_edit_path = the_post_path(@post) + "/comment-#{@comment.id}/edit"
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
