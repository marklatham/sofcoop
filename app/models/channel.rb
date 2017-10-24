class Channel < ApplicationRecord
  
  belongs_to :manager, class_name: 'User'
  has_many :posts
  has_many :votes
  has_one :standing
  has_many :past_standings
  
  mount_uploader :avatar, ChannelUploader
  
end
