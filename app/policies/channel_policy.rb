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

  def posts?
    true
  end

  def edit?
    user && user.is_admin?
  end

  def create?
    user && user.is_admin?
  end
  
  def update?
    edit?
  end

  def destroy?
    user && user.is_admin?
  end
  
end
