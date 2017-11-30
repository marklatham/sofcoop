class TagsController < ApplicationController
  
  def index
    @tags = ActsAsTaggableOn::Tag.where("taggings_count>0").sort_by{|tag| tag.taggings_count}.reverse!
  end

  def show
    @tag   = ActsAsTaggableOn::Tag.friendly.find(params[:slug])
    @posts = Post.tagged_with(@tag.name).select{|post| policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @posts = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def channel_tag
    @channel = Channel.find_by_slug(params[:channel_slug])
    @tag     = ActsAsTaggableOn::Tag.friendly.find(params[:slug])
    @posts   = Post.tagged_with(@tag.name).
             select{|post| post.channel && post.channel == @channel && policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @posts   = Kaminari.paginate_array(@posts).page(params[:page])
  end

  def author_tag
    @author  = User.find_by_username(params[:username])
    @tag     = ActsAsTaggableOn::Tag.friendly.find(params[:slug])
    @posts   = Post.tagged_with(@tag.name).
             select{|post| post.author && post.author == @author && policy(post).list?}.
             sort_by{|post| post.updated_at}.reverse!
    @posts_count = @posts.size
    @posts   = Kaminari.paginate_array(@posts).page(params[:page])
  end

end
