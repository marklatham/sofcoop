# https://github.com/mbleigh/acts-as-taggable-on#configuration
# To have an exact match covering special characters with MySql:
ActsAsTaggableOn.force_binary_collation = true

ActsAsTaggableOn.force_lowercase = true

ActsAsTaggableOn::Tag.class_eval do
  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]
end
