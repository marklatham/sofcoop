class UserPolicy < ApplicationPolicy

  def index?
    true
  end
  
  def show?
    case record.profile.visible
      when 4 then true
      when 3 then user
      when 2 then user && ( user.is_member? || user.is_admin? || user.is_moderator? )
      when 0 then user && ( user == record || user.is_admin? || user.is_moderator? )
    end
  end
  
  def create?
    user && user.is_admin?
  end
  
  def update?  # Mainly for moderation.
    user && ( user.is_admin? || 
    ( user.is_moderator? && record.is_moderator? == false && record.is_admin? == false ) )
  end

  def destroy?
    user && user.is_admin?
  end
  
  def author_posts?   # Only checked for private listing.
    user && ( user == record || user.is_admin? )
  end

  def channel_author?
    true
  end
  
  def permitted_attributes
    common_params = [:username, :avatar, :avatar_cache, :remove_avatar,
                     :remote_avatar_url, :profile_id]
    if user.is_admin?
      common_params + [:email, :mod_status, :is_member]
    elsif user == record
      common_params
    elsif edit?   # Same as update? above.
      [:mod_status]
    else
      []
    end
  end
  
end
