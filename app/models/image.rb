class Image < ApplicationRecord
  extend FriendlyId
  belongs_to :user
  mount_uploader :file, ImageUploader
  friendly_id :slug_candidates, use: [:slugged, :scoped, :history], scope: :user
  
  def slug_candidates
    if self.title.present?
      title = self.title.truncate(60, separator: ' ', omission: '').gsub('_', '-')
      ["#{title}",
      ["#{title}", '2'],
      ["#{title}", '3'],
      ["#{title}", '4'],
      ["#{title}", '5']]
    elsif self.description.present?
      "#{self.description.truncate(60, separator: ' ', omission: '').gsub('_', '-')}"
    elsif self.original_filename.present?
      "#{self.original_filename.split('.')[0...-1].join('.').gsub('_', '-')}"
    else
      "" # No candidate given here, so friendly_id will create a random string.
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
  
  def update_image_file(remote_file_url)
    if self.update(remote_file_url: remote_file_url)
      puts "Success!"
    else
      puts "Failed to update record. Handle the error."
    end
  end
  
end
