class Post < ApplicationRecord

  extend FriendlyId
  acts_as_taggable_on :tags  # Unless fixed?: stackoverflow.com/questions/18725506/acts-as-taggable-on
  belongs_to :author, class_name: 'User'
  belongs_to :channel, optional: true
  has_many :comments
  has_many :post_mods
  has_paper_trail
  friendly_id :slug_candidates, use: [:slugged, :scoped, :history], scope: :author
  
  attr_accessor :version_id  # When using posts controller to edit versions.
  attr_accessor :post_mod_id      # When using posts controller to edit post_mods.
  
  def slug_candidates
    if self.title.present?
      title = self.title.truncate(60, separator: ' ', omission: '').gsub('_', '-')
      ["#{title}",
      ["#{title}", '2'],
      ["#{title}", '3'],
      ["#{title}", '4'],
      ["#{title}", '5']]
    elsif self.body.present?
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
  
  def serialize
    existing_format = Time::DATE_FORMATS[:default]
    Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S.000000000 Z"
    object = "---\n"
    self.attributes.each do |attr_name, attr_value|
      object << attr_name + ": "
      if self.column_for_attribute(attr_name).type == :text
        object << attr_value.inspect
      else
        object << attr_value.to_s
      end
      object << "\n"
    end
    Time::DATE_FORMATS[:default] = existing_format
    return object
  end
  
  def to_post_mod(user)
    post_mod                    = PostMod.new
    post_mod.post               = self
    post_mod.author             = self.author
    post_mod.updater            = user
    post_mod.visible            = self.visible
    post_mod.title              = self.title
    post_mod.slug               = self.slug
    post_mod.body               = self.body
    post_mod.main_image         = self.main_image
    post_mod.channel            = self.channel
    post_mod.category           = self.category
    post_mod.mod_status         = self.mod_status
    post_mod.created_at         = self.created_at
    post_mod.version_updated_at = self.updated_at
    return post_mod
  end
  
end
