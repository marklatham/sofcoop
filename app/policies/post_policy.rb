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
    if record.category == "post"
      record.visible>1 || user_is_author_or_admin_or_manager?
    elsif record.category == "post_mod"
      user_is_author_or_admin_or_moderator?
    end
  end
  
  def list_private?  # Show this post in author's private list?
    record.category=="post" &&
      record.visible<2 && user_is_author_or_admin_or_manager?
  end
  
  def history?
    list? && user.is_member?
  end
  
  def show?
    if record.category == "post"
      case record.visible
        when 4 then true
        when 3 then user
        when 2 then user && (user.is_member? || user == record.author)
        when 0 then user_is_author_or_admin_or_manager?
      end
    elsif record.category == "post_mod"
      user_is_author_or_admin_or_moderator?
    else
      user && user.is_admin?
    end
  end
  
  def markdown?
    show?
  end
  
  def version?
    show?
  end
  
  def version_markdown?
    show?
  end
  
  def create?
    user
  end
  
  def update?
    case record.category
    when "channel_dropdown" then user_is_author_or_admin_or_manager?
    when "channel_profile" then user_is_author_or_admin_or_manager?
    else update_detailed?
    end
  end
  
  def update_detailed?
    return false if PaperTrail::Version.where("item_type = ? AND item_id = ? AND created_at > ?",
                                                   "Post", record.id, record.updated_at).present?
    case record.category
    when "post" then user_is_author_or_admin_or_manager?
    when "post_mod" then user_is_author_or_admin_or_manager?
    else user_is_author_or_admin?  # user_profile, home_page, any forgotten
    end
  end
  
  def approve?
    update? && record.category == "post_mod" &&
    ( user.is_admin? || ( user.is_moderator? && user != record.author ) )
  end
  
  def destroy?
    user_is_author_or_admin?
  end

  private

  def user_is_author_or_admin?
    user && ( user == record.author || user.is_admin? )
  end
  
  def user_is_author_or_admin_or_manager?
    user && ( user == record.author || user.is_admin? || ( record.channel && user == record.channel.manager ) )
  end
  
  def user_is_author_or_admin_or_moderator?
    user && ( user == record.author || user.is_admin? || user.is_moderator? )
  end
  
end
