class Image < ApplicationRecord
  extend FriendlyId
  belongs_to :user
  mount_uploader :file, ImageUploader
  friendly_id :slug_candidates, use: [:slugged, :scoped, :history], scope: :user
  
  # But :id not available when creating record, so FriendlyId will default to random string:
  def slug_candidates
    if self.title.present?
      [:title,
      [:title, '2'],
      [:title, '3'],
      [:title, '4'],
      [:title, '5'],
      [:title, :id] ]
    elsif self.description.present?
      "#{self.description.truncate(40, separator: ' ', omission: '')}"
    elsif self.remote_file_url.present?
      "#{self.remote_file_url}"
    else
      :id
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
