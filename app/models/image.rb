class Image < ApplicationRecord
  extend FriendlyId
  belongs_to :user
  mount_uploader :file, ImageUploader
  friendly_id :slug_candidates, use: [:slugged, :scoped], scope: :user
  
  # But :id not available when creating record, so FriendlyId will default to random string:
  def slug_candidates
    if self.title.present?
      ["#{self.title.truncate(60, separator: ' ', omission: '')}",
      ["#{self.title.truncate(60, separator: ' ', omission: '')}", '2'],
      ["#{self.title.truncate(60, separator: ' ', omission: '')}", '3'],
      ["#{self.title.truncate(60, separator: ' ', omission: '')}", '4'],
      ["#{self.title.truncate(60, separator: ' ', omission: '')}", '5']]
    elsif self.description.present?
      "#{self.description.truncate(60, separator: ' ', omission: '')}"
    elsif self.original_filename.present?
      "#{self.original_filename.split('.')[0...-1].join('.')}"
    else
      "" # No candidate given here, so friendly_id will create a random string.
    end
  end
  
  validates_presence_of :slug
  after_validation :move_friendly_id_error_to_title

  def move_friendly_id_error_to_title
    errors.add :title, *errors.delete(:friendly_id) if errors[:friendly_id].present?
  end
  
end
