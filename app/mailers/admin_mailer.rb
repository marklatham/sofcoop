class AdminMailer < ApplicationMailer

  def new_registration(user)
    @user = user
    mail   to: Rails.application.secrets.admin_email,
      subject: "New registration"
  end
  
  def username_changed(user, old_username)
    @user = user
    @old_username = old_username
    mail   to: Rails.application.secrets.admin_email,
      subject: "Username changed"
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

  def new_post(post, post_url)
    @post = post
    @post_url = post_url
    mail   to: Rails.application.secrets.admin_email,
      subject: "New post"
  end

  def post_assigned(post, channel, current_user)
    @post = post
    @channel = channel
    @current_user = current_user
    mail   to: [channel.user.email, post.user.email],
           cc: Rails.application.secrets.admin_email,
      subject: "Post assigned to channel"
  end

  def post_unassigned(post, channel, current_user)
    @post = post
    @channel = channel
    @current_user = current_user
    mail   to: [channel.user.email, post.user.email],
           cc: Rails.application.secrets.admin_email,
      subject: "Post UNassigned FROM channel"
  end

  def filenames_update(log_report)
    @log_report = log_report
    mail   to: Rails.application.secrets.admin_email,
      subject: "Filenames Update"
  end
  
end
