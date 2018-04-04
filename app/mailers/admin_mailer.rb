class AdminMailer < ApplicationMailer

  def account_cancelled(user, posts_count)
    @user = user
    @posts_count = posts_count
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "Account cancelled"
  end
  
  def approved_comment(comment, comment_url, current_user)
    @comment = comment
    @comment_url = comment_url
    @current_user = current_user
    moderators = User.with_role :moderator
    moderator_emails = []
    for moderator in moderators
      moderator_emails << moderator.email unless moderator == @comment.author
    end
    mail   to: @comment.author.email,
          bcc: moderator_emails,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Approved comment on: " + @comment.post.title
  end
  
  def approved_post(post, post_url, current_user)
    @post = post
    @post_url = post_url
    @current_user = current_user
    moderators = User.with_role :moderator
    moderator_emails = []
    for moderator in moderators
      moderator_emails << moderator.email unless moderator == post.author
    end
    mail   to: @post.author.email,
          bcc: moderator_emails,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Approved post: " + @post.title
  end
  
  def cancel_account_manually(user, posts_count)
    @user = user
    @posts_count = posts_count
    mail   to: Sofcoop::Application.secrets.admin_email,
           cc: @user.email,
      subject: "Cancel account manually"
  end
  
  def comment_put_on_mod(comment, comment_url, current_user)
    @comment = comment
    @comment_url = comment_url
    @current_user = current_user
    moderators = User.with_role :moderator
    moderator_emails = []
    for moderator in moderators
      moderator_emails << moderator.email unless moderator == @comment.author
    end
    mail   to: @comment.author.email,
          bcc: moderator_emails,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Comment put on moderation: on post: " + @comment.post.title
  end
  
  def filenames_update(log_report)
    @log_report = log_report
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "Filenames Update"
  end
  
  def hid_dupes(version)
    @version = version
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "Hid Dupe Versions"
  end
  
  def moderate_new_comment(comment, comment_url, current_user)
    @comment = comment
    @comment_url = comment_url
    @current_user = current_user
    moderators = User.with_role :moderator
    moderator_emails = []
    for moderator in moderators
      moderator_emails << moderator.email unless moderator == comment.author
    end
    mail   to: moderator_emails,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Please moderate comment # " + @comment.id.to_s
  end
  
  def moderate_post(post, post_url, current_user, new_or_updated)
    @post = post
    @post_url = post_url
    @current_user = current_user
    @created_or_updated = new_or_updated
    @created_or_updated = "created" if new_or_updated == "new"
    moderators = User.with_role :moderator
    moderator_emails = []
    for moderator in moderators
      moderator_emails << moderator.email unless moderator == post.author
    end
    mail   to: moderator_emails,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Please moderate #{new_or_updated} post: " + @post.title
  end
  
  def new_post(post, post_url)
    @post = post
    @post_url = post_url
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "New post"
  end

  def new_registration(user)
    @user = user
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "New registration"
  end
  
  def post_assigned(post, post_url, channel, current_user)
    @post = post
    @post_url = post_url
    @channel = channel
    @current_user = current_user
    mail   to: [channel.manager.email, post.author.email],
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Post assigned to channel"
  end
  
  def post_process(admin_email, post, post_url, body_before, body_after, event)
    @admin_email = admin_email
    @post = post
    @post_url = post_url
    @body_before = body_before
    @body_after = body_after
    @event = event
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "Post process"
  end
  
  def post_put_on_mod(post, post_url, current_user)
    @post = post
    @post_url = post_url
    @current_user = current_user
    moderators = User.with_role :moderator
    moderator_emails = []
    for moderator in moderators
      moderator_emails << moderator.email unless moderator == post.author
    end
    mail   to: @post.author.email,
          bcc: moderator_emails,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Post put on moderation: " + @post.title
  end
  
  def post_unassigned(post, post_url, channel, current_user)
    @post = post
    @post_url = post_url
    @channel = channel
    @current_user = current_user
    mail   to: [channel.manager.email, post.author.email],
           cc: Sofcoop::Application.secrets.admin_email,
      subject: "Post UNassigned FROM channel"
  end

  def username_changed(user, old_username)
    @user = user
    @old_username = old_username
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "Username changed"
  end
  
  def user_moderation(user, moderator)
    @user = user
    if @user.mod_status == true
      @subject = "You are on moderation"
    else
      @subject = "You are off moderation"
    end
    mail   to: @user.email,
          bcc: moderator.email,
           cc: Sofcoop::Application.secrets.admin_email,
      subject: @subject
  end
  
  def votes_tally(cutoff_time)
    @cutoff_time = cutoff_time
    mail   to: Sofcoop::Application.secrets.admin_email,
      subject: "Votes tally"
  end
  
end
