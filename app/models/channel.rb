class Channel < ApplicationRecord
  
  belongs_to :user
  has_many :posts
  
  mount_uploader :avatar, ChannelUploader
  
end
