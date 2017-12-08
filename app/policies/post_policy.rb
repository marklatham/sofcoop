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

  def author_posts?
    true
  end
  
  def list?  # Should this post's title etc (not body) appear in lists?
    record.category=="post" &&
    ( record.visible>1 || user_is_author_or_admin_or_manager? )
  end
  
  def list_private?  # Show this post in author's private list?
    record.category=="post" &&
      record.visible<2 && user_is_author_or_admin_or_manager?
  end
  
  def show?
    if record.category == "post"
      case record.visible
        when 4 then true
        when 3 then user
        when 2 then user && user.is_member?
        when 0 then user_is_author_or_admin_or_manager?
      end
    else
      user && user.is_admin?
    end
  end
  
  def markdown?
    record.visible > 2 && create?
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
      user == record.author || user.is_admin?
    end
  end
  
  def user_is_author_or_admin_or_manager?
    if user
      user == record.author || user.is_admin? || record.channel && user == record.channel.manager
    end
  end
  
end
