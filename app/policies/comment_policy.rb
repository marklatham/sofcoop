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
  
  def edit?  # Same as update except 60.minutes instead of 65.minutes. DRY??
    if user == nil  # There is no user logged in.
      false
    elsif user.is_admin?
      true
    elsif user.is_moderator? && user != record.author
      if record.author.is_moderator?
        false
      else
        true
      end
    elsif user == record.author
      if Time.now > 60.minutes.since(record.created_at)
        false
      else
        latest_comment = Comment.where("post_id = ?", record.post.id).order("created_at").last
        if record == latest_comment
          true
        else
          false
        end
      end
    else # user != record.author
      false
    end
  end
  
  def update?
    if user == nil  # There is no user logged in.
      false
    elsif user.is_admin?
      true
    elsif user.is_moderator? && user != record.author
      if record.author.is_moderator?
        false
      else
        true
      end
    elsif user == record.author
      if Time.now > 65.minutes.since(record.created_at)
        false
      else
        latest_comment = Comment.where("post_id = ?", record.post.id).order("created_at").last
        if record == latest_comment
          true
        else
          false
        end
      end
    else # user != record.author
      false
    end
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
