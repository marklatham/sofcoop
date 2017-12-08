class TagsController < ApplicationController
  
  def index
    @tags = ActsAsTaggableOn::Tag.where("taggings_visible>0").order("taggings_count DESC, name")
  end

end
