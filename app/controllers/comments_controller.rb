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

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    redirect_to the_post_path(@comment.post)
  end

  private

  def comment_params
    params.require(:comment).permit(:post_id, :user_id, :body)
  end

end
