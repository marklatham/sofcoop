class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  helper_method :is_author_or_admin?
  helper_method :is_uploader_or_admin?
  require 'httparty'
  
  # A more specific version is in post_policy, since it's handy there.
  def is_author_or_admin?(user, post)
    if user
      user == post.user || user.is_admin?
    end
  end
  
  # A more specific version is in image_policy, since it's handy there.
  def is_uploader_or_admin?(user, image)
    if user
      user == image.user || user.is_admin?
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
