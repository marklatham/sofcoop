class Users::SessionsController < Devise::SessionsController
# before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    @body_class = 'grayback'
    super
  end

  # POST /resource/sign_in
  def create
    session[:ballot] = Ballot.new    # Don't show any pre-login votes.
    super do |resource|
      if resource.sign_in_count < 2
        flash[:notice] = 'Welcome! We gave you the username @' +
         resource.username + ' for now. You can change it at ' +
         view_context.link_to("Edit Account", edit_user_registration_path)+'.'.html_safe
      end
    end
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
