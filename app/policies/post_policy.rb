class PostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_admin?
        scope.all.order(updated_at: :desc)
      else
        user.posts
      end
    end
  end

  def index?
    true
  end

  def search?
    true
  end

  def user_posts?
    true
  end
  
  def show?
    record.visible > 1 || user_is_author_or_admin_or_manager?
    # More granular restrictions (hiding post.body) are coded in the view
    # to give more granular "unauthorized" messages.
  end

  def edit?
    user_is_author_or_admin_or_manager?
  end

  def create?
    user
  end
  
  def update?
    edit?
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
  
  def user_is_author_or_admin_or_manager?
    if user
      user == record.user || user.is_admin? || record.channel && user == record.channel.user
    end
  end
  
end
