class UserPolicy < ApplicationPolicy

  def index?
    true
  end
  
  def show?
    if record.profile.visible == 4
      true
    elsif record.profile.visible == 3
      user
    elsif record.profile.visible == 2
      user && user.is_member?
    elsif record.profile.visible == 0
      user == record || ( user && user.is_admin? )
    end
  end
  
end
