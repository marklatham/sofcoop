class Channel < ApplicationRecord
  
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :profile, class_name: 'Post', optional: true
  belongs_to :dropdown, class_name: 'Post', optional: true
  has_many :posts
  has_many :post_mods
  has_many :votes
  has_one :standing
  has_many :past_standings
  
  mount_uploader :avatar, ChannelUploader
  
end
