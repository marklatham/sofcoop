class ChannelPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_admin?
        scope.all.order(updated_at: :desc)
      else
        user.channels
      end
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def channel_posts?
    true
  end

  def channel_author?
    true
  end

  def create?
    user && user.is_admin?
  end
  
  def update?
    user && user.is_admin?
  end

  def destroy?
    user && user.is_admin?
  end
  
end
