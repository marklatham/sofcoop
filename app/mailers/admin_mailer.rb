class AdminMailer < ApplicationMailer

  def new_registration(user)
    @user = user
    mail   to: Rails.application.secrets.admin_email,
      subject: "New registration"
  end

  def account_cancelled(user, pages_count)
    @user = user
    @pages_count = pages_count
    mail   to: Rails.application.secrets.admin_email,
      subject: "Account cancelled"
  end

  def cancel_account_manually(user, pages_count)
    @user = user
    @pages_count = pages_count
    mail   to: Rails.application.secrets.admin_email,
           cc: @user.email,
      subject: "Cancel account manually"
  end

  def new_page(page)
    @page = page
    mail   to: Rails.application.secrets.admin_email,
      subject: "New page"
  end
end
