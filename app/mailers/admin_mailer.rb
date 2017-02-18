class AdminMailer < ApplicationMailer

  def new_registration(user)
    @user = user
    mail   to: Rails.application.secrets.admin_email,
      subject: "New registration"
  end

  def account_cancelled(user)
    @user = user
    mail   to: Rails.application.secrets.admin_email,
      subject: "Account cancelled"
  end

  def new_page(page)
    @page = page
    mail   to: Rails.application.secrets.admin_email,
      subject: "New page"
  end
end
