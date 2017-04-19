class Post < ApplicationRecord
  extend FriendlyId
  belongs_to :user
  friendly_id :slug_candidates, use: [:slugged, :scoped, :history], scope: :user
  
  def slug_candidates
    if self.title.present?
      title = self.title.truncate(60, separator: ' ', omission: '').gsub('_', '-')
      ["#{title}",
      ["#{title}", '2'],
      ["#{title}", '3'],
      ["#{title}", '4'],
      ["#{title}", '5']]
    else
      "#{self.body.markdown2html.strip_tags.truncate(60, separator: ' ', omission: '').gsub('_', '-')}"
    end
  end
  
  def should_generate_new_friendly_id?
    title_changed? || super
  end
  
  validates_presence_of :slug
  after_validation :move_friendly_id_error_to_title

  def move_friendly_id_error_to_title
    errors.add :title, *errors.delete(:friendly_id) if errors[:friendly_id].present?
  end
  
end
