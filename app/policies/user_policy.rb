class UserPolicy < ApplicationPolicy

  def index?
    true
  end
  
  def show?
    case record.profile.visible
      when 4 then true
      when 3 then user
      when 2 then user && user.is_member?
      when 0 then user && ( user == record || user.is_admin? )
    end
  end
  
  def author_posts? # Only checked for private listing.
    user && ( user == record || user.is_admin? )
  end

  def channel_author?
    true
  end
  
  def permitted_attributes
    common_params = [:username, :avatar, :avatar_cache, :remove_avatar,
                     :remote_avatar_url, :profile_id]
    if user.is_admin?
      common_params + [:mod, :is_member]
    elsif user.is_moderator?
      common_params + [:mod]
    else
      common_params
    end
  end
  
end
