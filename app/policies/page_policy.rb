class PagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin
        scope.all.order(updated_at: :desc)
      else
        user.pages
      end
    end
  end

  def index?
    true
  end
  
  def show?
    record.visible > 1 || user_is_author_or_admin?
    # More granular restrictions (hiding page.body) are coded in the view
    # to give more granular "unauthorized" messages.
  end

  def edit?
    user_is_author_or_admin?
  end

  def create?
    @current_user
  end
  
  def update?
    user_is_author_or_admin?
  end

  def destroy?
    user_is_author_or_admin?
  end

  private

  # A more general version is in application_controller, but this version is handy here:
  def user_is_author_or_admin?
    if user
      user == record.user || user.is_admin?
    end
  end
  
end
