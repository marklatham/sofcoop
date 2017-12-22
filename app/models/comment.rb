class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :author, class_name: 'User'
  has_paper_trail
end
