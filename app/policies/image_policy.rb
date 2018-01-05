class ImagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_admin?
        scope.all.order(updated_at: :desc)
      else
        user.images
      end
    end
  end

  def index?
    user
  end

  def user_images?
    user
  end
  
  def show?
    user
  end

  def create?
    user
  end
  
  def update?
    user_is_uploader_or_admin?
  end

  def destroy?
    user_is_uploader_or_admin?
  end

  private

  # A more general version is in application_controller, but this version is handy here:
  def user_is_uploader_or_admin?
    if user
      user == record.user || user.is_admin?
    end
  end
  
end
