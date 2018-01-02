class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :set_search
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  helper_method :is_author_or_admin?
  helper_method :the_post_path
  helper_method :the_post_url
  helper_method :nav_channels
  
  require 'httparty'

  def set_search
    @search = Post.ransack(params[:q])
  end
  
  # More specific versions are in [resource]_policy, since handy there.
  # So far only using this where resource is a post.
  def is_author_or_admin?(user, resource)
    if user
      user == resource.author || user.is_admin?
    end
  end
  
  def vanity_slugs
    # Should be unique in both columns. See rails routes for words already in use.
    {
    26 => "terms",
    28 => "privacy",
    29 => "markdown",
    84 => "about"
    }
  end
  
  def the_post_path(post)
    channel_slug = nil
    channel_slug = post.channel.slug if post.channel
    if vanity_slug = vanity_slugs[post.id]
      vanity_path(vanity_slug)
    else
      case post.category
        when "post" then post_path(channel_slug, post.author.username, post.slug)
        when "channel_dropdown" then channel_path(channel_slug) # Not very relevant but no better idea.
        when "channel_profile" then channel_path(channel_slug)
        when "user_profile" then user_path(post.author.username)
        else post_path(channel_slug, post.author.username, post.slug)
      end
    end
  end
  
  def the_post_url(post)
    channel_slug = nil
    channel_slug = post.channel.slug if post.channel
    if vanity_slug = vanity_slugs[post.id]
      vanity_url(vanity_slug)
    else
      case post.category
        when "post" then post_url(channel_slug, post.author.username, post.slug)
        when "channel_dropdown" then channel_url(channel_slug) # Not very relevant but no better idea.
        when "channel_profile" then channel_url(channel_slug)
        when "user_profile" then user_url(post.author.username)
        else post_url(channel_slug, post.author.username, post.slug)
      end
    end
  end
  
  def nav_channels
    response = []
    standings = Standing.all.order('rank ASC')
    for standing in standings[0..8]
      response << standing.channel
    end
    response << Channel.where(slug: 'admin').first # Insert admin channel.
    for standing in standings[9..-1]
      response << standing.channel
    end
    return response
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

  def find_ballot 
    session[:ballot] ||= Ballot.new
  end
  
end
