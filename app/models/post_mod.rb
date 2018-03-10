class PostMod < ApplicationRecord
  belongs_to :post
  belongs_to :author, class_name: 'User'
  belongs_to :updater, class_name: 'User'
  belongs_to :channel, optional: true
end
