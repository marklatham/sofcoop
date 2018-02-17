module ApplicationHelper
  
  def visible_options
    [['Author & Admin', '0'], ['Logged-in Members', '2'], ['Logged-in Users', '3'], ['The World', '4']]
  end
  
  def my_private_posts
    current_user && current_user.posts.where(category:"post").select{|post| policy(post).list_private?}.
                                                              sort_by{|post| post.updated_at}.reverse!
  end
  
  def assignee_channels
    array = [['None', nil]]
    for channel in nav_channels
      array << [channel.name, channel.id.to_s]
    end
    return array
  end
  
  def conditional_strftime(type, datetime, cutoff)
    if datetime > cutoff.months.ago
      case type
        when "month_day" then datetime.strftime("%b %e")
        when "weekday_date_time" then datetime.strftime("%A, %B %e at %l:%M %P UTC")
        else datetime.strftime("%A, %B %e at %l:%M %P UTC")
      end
    else
      case type
        when "month_day" then datetime.strftime("%Y-%m-%d")
        when "weekday_date_time" then datetime.strftime("%B %e, %Y")
        else datetime.strftime("%B %e, %Y")
      end
    end
  end
  
end
