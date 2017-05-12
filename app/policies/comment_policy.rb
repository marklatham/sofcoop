class CommentPolicy < ApplicationPolicy
# Most are not currently used, but coded for possible future use:

  class Scope < Scope
    def resolve
      if user.is_admin?
        scope.all.order(updated_at: :desc)
      else
        user.comments
      end
    end
  end

  def index?
    true
  end

  def user_comments?
    true
  end
  
  def show?
    record.post.visible > 1 || user_is_author_or_admin?
  end

  def edit?
    user_is_author_or_admin?
  end

  def create?
    user
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
