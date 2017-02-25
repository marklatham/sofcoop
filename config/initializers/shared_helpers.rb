class String
  
  # Suggested in 2009-04-21 note to http://apidock.com/rails/ActionView/Helpers/SanitizeHelper/strip_tags:
  def strip_tags
    ActionController::Base.helpers.strip_tags(self)
  end

  def markdown2html
    Kramdown::Document.new(self).to_html.html_safe
  end
  
end
