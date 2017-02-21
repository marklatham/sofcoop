class String
  
  def strip_tags
    ActionController::Base.helpers.strip_tags(self)
  end

  def markdown2html
    Kramdown::Document.new(self).to_html.html_safe
  end
  
end
