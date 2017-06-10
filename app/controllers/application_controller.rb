class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :set_search
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  helper_method :is_author_or_admin?
  helper_method :the_post_path
  helper_method :the_post_url
  require 'httparty'

  def set_search
    @search = Post.ransack(params[:q])
  end
  
  # More specific versions are in [resource]_policy, since handy there.
  # So far only using this where resource is a post.
  def is_author_or_admin?(user, resource)
    if user
      user == resource.user || user.is_admin?
    end
  end
  
  def the_post_path(post)
    if post.channel
      channel_post_path(post.channel.slug, post.user.username, post.slug)
    else
      post_path(post.user.username, post.slug)
    end
  end
  
  def the_post_url(post)
    if post.channel
      channel_post_url(post.channel.slug, post.user.username, post.slug)
    else
      post_url(post.user.username, post.slug)
    end
  end

  protected
  
  def render_404
    raise ActionController::RoutingError.new('Not Found')
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referrer || root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
  end
  
end
