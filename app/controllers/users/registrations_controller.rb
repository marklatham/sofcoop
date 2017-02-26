class Users::RegistrationsController < Devise::RegistrationsController
# before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    @body_class = 'grayback'
    super
  end

  # POST /resource
  def create
    super do |resource|
      resource.username = 'user' + resource.id.to_s
      resource.save
    end
  end

  # GET /resource/edit
  def edit
    @body_class = 'grayback'
    super
  end

  def change_password
    @body_class = 'grayback'
  end

  # PUT /resource
  def update # TO DO: disallow username = "user*" unless = "user" + id.to_s
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    if account_update_params[:username].first(4).downcase == 'user'
      flash[:error] = "Sorry, edited username can't start with 'user'."
      redirect_back(fallback_location: user_path(resource.username)) and return
    elsif account_update_params[:username].first(1) == '_' || account_update_params[:username].last(1) == '_'
      flash[:error] = "Sorry, username can't start or end with underscore _"
      redirect_back(fallback_location: user_path(resource.username)) and return
    elsif account_update_params[:username].include? '__'
      flash[:error] = "Sorry, username can't include a double underscore __"
      redirect_back(fallback_location: user_path(resource.username)) and return
    end
    
    resource_updated = update_resource(resource, account_update_params)
    if resource_updated
      AdminMailer.new_registration(resource).deliver  # notify admin
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
          :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      bypass_sign_in resource, scope: resource_name
      respond_with resource, location: user_path(resource.username)
    else
      clean_up_passwords resource
      flash[:notice] = flash[:notice].to_a.concat resource.errors.full_messages
      redirect_back(fallback_location: user_path(resource.username))
    end
  end

  # DELETE /resource
  
  def cancel_account
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    @pages = Page.where(user_id: resource.id)
    @body_class = 'grayback'
  end

  def destroy
    super
    AdminMailer.account_cancelled(resource).deliver  # notify admin
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    super
  end
  
  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end

  # The default url to be used after updating a resource.
  def after_update_path_for(resource)
    super(resource)
  end
  
end
