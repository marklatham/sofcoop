class TagsController < ApplicationController
  def index
    @tags = ActsAsTaggableOn::Tag.all.sort_by{|tag| tag.taggings_count}.reverse!
  end

  def show
    @tag =  ActsAsTaggableOn::Tag.find(params[:id])
    @posts = Post.tagged_with(@tag.name).
             select{|post| post.visible > 1 || is_author_or_admin?(current_user, post)}.
             sort_by{|post| post.updated_at}.reverse!
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end
end
