class Channel < ApplicationRecord
  
  belongs_to :user
  has_many :posts
  has_many :votes
  
  mount_uploader :avatar, ChannelUploader
  
end
