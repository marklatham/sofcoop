class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :userpage_path
  helper_method :userpage_url
  helper_method :userpage_edit
  
  def userpage_path(page)
    '/@' + page.user.username + '/' + page.slug
  end
  
  def userpage_url(page)
    root_url + userpage_path(page)
  end
  
  def userpage_edit(page)
    '/@' + page.user.username + '/' + page.slug + '/edit'
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
