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

  def edit?
    user_is_admin?
  end

  def create?
    user_is_admin?
  end
  
  def update?
    user_is_admin?
  end

  def destroy?
    user_is_admin?
  end
  
end
