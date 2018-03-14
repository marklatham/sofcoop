class PostMod < ApplicationRecord
  belongs_to :post
  belongs_to :author, class_name: 'User'
  belongs_to :updater, class_name: 'User'
  belongs_to :channel, optional: true
  
  def to_post # Delete later if not used.
    post            = self.post
    post.author     = self.author
    post.visible    = self.visible
    post.title      = self.title
    post.slug       = self.slug
    post.body       = self.body
    post.main_image = self.main_image
    post.channel    = self.channel
    post.category   = self.category
    post.mod_status = self.mod_status # Reset here or in other code?
    post.created_at = self.created_at # Should be same anyway.
    post.updated_at = self.version_updated_at # Need this for approve process.
    return post
  end
  
end
