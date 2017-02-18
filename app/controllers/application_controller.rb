class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :username_path
  helper_method :username_url
  helper_method :userpage_path
  helper_method :userpage_url
  
  def username_path(user)
    if user.username.present?
      '/@' + user.username
    else
      user_path(user)
    end
  end
  
  def username_url(user)
    root_url + username_path(user)
  end
  
  def userpage_path(page)
    '/@' + page.user.username + '/' + page.slug
  end
  
  def userpage_url(page)
    root_url + userpage_path(page)
  end
  
  protected

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
  end

end
