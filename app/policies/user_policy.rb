class UserPolicy < ApplicationPolicy

  def index?
    @user.is_admin?
  end

  def show?
    true
  end

end
