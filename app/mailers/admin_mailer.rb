class AdminMailer < ApplicationMailer

  def new_registration(user)
    @user = user
    mail   to: Rails.application.secrets.admin_email,
      subject: "New registration"
  end

  def account_cancelled(user, posts_count)
    @user = user
    @posts_count = posts_count
    mail   to: Rails.application.secrets.admin_email,
      subject: "Account cancelled"
  end

  def cancel_account_manually(user, posts_count)
    @user = user
    @posts_count = posts_count
    mail   to: Rails.application.secrets.admin_email,
           cc: @user.email,
      subject: "Cancel account manually"
  end

  def new_post(post)
    @post = post
    mail   to: Rails.application.secrets.admin_email,
      subject: "New post"
  end
end
