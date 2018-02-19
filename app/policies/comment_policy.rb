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
    policy(record.post).show?
  end

  def create?
    user
  end
  
  def update?
    user_is_author_or_admin_or_moderator?
  end

  def destroy?
    user_is_author_or_admin_or_moderator?
  end

  private

  def user_is_author_or_admin?
    if user
      user == record.author || user.is_admin?
    end
  end
  
  def user_is_author_or_admin_or_moderator?
    user && ( user == record.author || user.is_admin? || user.is_moderator? )
  end
  
end
