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
    elsif record.mod_status == true
      user_is_author_or_admin_or_moderator?
    end
  end
  
  def list_private?  # Show this post in author's private list?
    record.category=="post" &&
      record.visible<2 && user_is_author_or_admin_or_manager?
  end
  
  def history?
    show?
  end
  
  def moderating?  # See posts under moderation in post_mod table.
    user_is_author_or_admin_or_moderator?
  end
  
  def post_mod?
    moderating?
  end
  
  def show?
    if record.category == "post" && record.mod_status == false
      case record.visible
        when 4 then true
        when 3 then user
        when 2 then user && (user.is_member? || user == record.author)
        when 0 then user_is_author_or_admin_or_manager?
      end
    elsif record.mod_status == true
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
    # The case user.mod_status == true is handled in the controller.
    if PostMod.where("post_id = ? AND updated_at > ?", record.id, record.updated_at).present?
      return false
    else
      case record.category
      when "channel_dropdown" then user_is_author_or_admin_or_manager?
      when "channel_profile" then user_is_author_or_admin_or_manager?
      when "post" then update_detailed?
      else user_is_author_or_admin?  # user_profile, home_page, any forgotten
      end
    end
  end
  
  def update_detailed?
    if record.mod_status == true
      user_is_author_or_admin_or_moderator?
    else
      user_is_author_or_admin?
    end
  end
  
  def edit_tags?
    if user && user == record.author && user.mod_status == true && record.mod_status == false
      false
    else
      true  # Other conditions giving false are imposed in post_policy update and in _form view.
    end
  end
  
  def moderate?
    user && user.is_moderator?
  end

  def approve?
    update? && record.mod_status == true && user &&
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
    user && ( user == record.author || user.is_admin? || ( record.channel.present? && user == record.channel.manager ) )
  end
  
  def user_is_author_or_admin_or_moderator?
    user && ( user == record.author || user.is_admin? || user.is_moderator? )
  end
  
  def user_is_author_admin_mgr_or_mod?
    user && ( user == record.author || user.is_admin? || user.is_moderator? ||
               ( record.channel.present? && user == record.channel.manager )  )
  end
  
end
