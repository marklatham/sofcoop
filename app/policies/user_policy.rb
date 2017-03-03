class UserPolicy < ApplicationPolicy

  def index?
    @user
  end

  def show?
    true
  end

end
