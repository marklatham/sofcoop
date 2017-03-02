class Users::RegistrationsController < DeviseController
# before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  prepend_before_action :require_no_authentication, only: [:new, :create, :cancel]
  prepend_before_action :authenticate_scope!, only: [:edit, :update, :destroy]
  prepend_before_action :set_minimum_password_length, only: [:new, :edit]

  # GET /resource/sign_up
  def new
    @body_class = 'grayback'
    build_resource({})
    respond_with resource
  end

  # POST /resource
  def create
    build_resource(sign_up_params)
    # Username can't be nil, but want to use id, so guess it:
    resource.username = 'user' + User.maximum(:id).next.to_s
    resource.save
    # Then correct the guess in case previous user deleted:
    resource.username = 'user' + resource.id.to_s
    resource.save
    AdminMailer.new_registration(resource).deliver  # notify admin
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # GET /resource/edit
  def edit
    @body_class = 'grayback'
    render :edit
  end

  def change_password
    @body_class = 'grayback'
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    if account_update_params[:username]
      if /\Auser[0-9]+\z/.match(account_update_params[:username].downcase)
        unless account_update_params[:username].downcase == 'user' + resource.id.to_s
          flash[:error] = 
          "Sorry, edited username can't be 'user' followed by a number unless it's your user id number (" +
            resource.id.to_s + ")."
          redirect_back(fallback_location: user_path(resource.username)) and return
        end
      elsif account_update_params[:username].first(1) == '_' || account_update_params[:username].last(1) == '_'
        flash[:error] = "Sorry, username can't start or end with underscore _"
        redirect_back(fallback_location: user_path(resource.username)) and return
      elsif account_update_params[:username].include? '__'
        flash[:error] = "Sorry, username can't include a double underscore __"
        redirect_back(fallback_location: user_path(resource.username)) and return
      end
    end
    
    resource_updated = update_resource(resource, account_update_params)
    if resource_updated
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

  # GET /cancel_account (form)
  def cancel_account
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    @pages = Page.where(user_id: resource.id)
    @body_class = 'grayback'
  end

  # DELETE /resource
  def destroy
    pages = Page.where(user_id: resource.id)
    pages_count = pages.count
    if pages.any?
      # I thought :delete_content would be a boolean, but it's a string!:
      if params[:user][:delete_content] == 'true'
        for page in pages
          page.destroy
        end
      else
        flash[:notice] = 'Thank you for leaving us your pages!
                          Admin will delete your account manually soon.
                          You will receive confirmation by email.'
        AdminMailer.cancel_account_manually(resource, pages_count).deliver
        redirect_to root_path and return
      end
    end
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
    AdminMailer.account_cancelled(resource, pages_count).deliver
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    expire_data_after_sign_in!
    redirect_to new_registration_path(resource_name)
  end
  
  protected

  def update_needs_confirmation?(resource, previous)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      previous != resource.unconfirmed_email
  end

  # By default we want to require a password checks on update.
  # You can overwrite this method in your own RegistrationsController.
  def update_resource(resource, params)
    resource.update_with_password(params)
  end

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash=nil)
    self.resource = resource_class.new_with_session(hash || {}, session)
  end

  # Signs in a user on sign up. You can overwrite this method in your own
  # RegistrationsController.
  def sign_up(resource_name, resource)
    sign_in(resource_name, resource)
  end

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  # The path used after sign up for inactive accounts. You need to overwrite
  # this method in your own RegistrationsController.
  def after_inactive_sign_up_path_for(resource)
    scope = Devise::Mapping.find_scope!(resource)
    router_name = Devise.mappings[scope].router_name
    context = router_name ? send(router_name) : self
    context.respond_to?(:root_path) ? context.root_path : "/"
  end

  # The default url to be used after updating a resource. You need to overwrite
  # this method in your own RegistrationsController.
  def after_update_path_for(resource)
    signed_in_root_path(resource)
  end

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", force: true)
    self.resource = send(:"current_#{resource_name}")
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up)
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def account_update_params
    devise_parameter_sanitizer.sanitize(:account_update)
  end

  def translation_scope
    'devise.registrations'
  end
  
end
