module ApplicationHelper
  
  def visible_options
    [['Author & Admin', '0'], ['Logged-in Users', '3'], ['The World', '4']]
  end
  
  def channels_array
    [['None', nil], ['Admin', '5'], ['Channel 3', '6']]
  end
  
  def conditional_strftime(datetime, cutoff)
    if datetime > cutoff.months.ago
      datetime.strftime("%A, %B %e at %l:%M %P Pacific")
    else
      datetime.strftime("%B %e, %Y")
    end
  end
  
end
