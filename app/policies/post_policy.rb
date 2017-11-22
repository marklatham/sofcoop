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
  
  def list?  # Should this post's title etc (not body) appear in lists?
    record.category == "post" && ( record.visible > 1 || user_is_author_or_admin_or_manager? )
    # Before changing this, better find & check all "policy(post).list?"
  end
  
  def show?
    if record.category != "post"
      user.is_admin?
    elsif record.visible == 4
      true
    elsif record.visible == 3
      user
    elsif record.visible == 2
      user && user.is_member?
    elsif record.visible == 0
      user_is_author_or_admin_or_manager?
    end
    # Before changing this, better find & check all "policy(post).show?"
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
