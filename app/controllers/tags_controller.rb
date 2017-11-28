class TagsController < ApplicationController
  def index
    @tags = ActsAsTaggableOn::Tag.where("taggings_count>0").sort_by{|tag| tag.taggings_count}.reverse!
  end

  def show
    @tag   = ActsAsTaggableOn::Tag.friendly.find(params[:slug])
    @posts = Post.tagged_with(@tag.name).select{|post| policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end
end
