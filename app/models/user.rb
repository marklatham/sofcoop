class User < ApplicationRecord
  
  has_many :posts, foreign_key: 'author_id'
  has_many :images
  has_many :comments
  has_many :votes
  
  attr_accessor :delete_content
  
  mount_uploader :avatar, AvatarUploader
  
  extend FriendlyId
  friendly_id :username, :use => [:slugged, :history]

  VALID_USERNAME_REGEX = /\A[a-zA-Z0-9_]+\z/
  validates :username, length: { maximum: 15, minimum: 2 },
            format: { with: VALID_USERNAME_REGEX }, 
            uniqueness: { case_sensitive: false },
            :allow_nil => false
  
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable, :omniauthable,
         omniauth_providers: [:twitter, :facebook, :google_oauth2]
  
  def should_generate_new_friendly_id?
    username_changed? || super
  end
  
  validates_presence_of :slug
  after_validation :move_friendly_id_error_to_username

  def move_friendly_id_error_to_username
    errors.add :username, *errors.delete(:friendly_id) if errors[:friendly_id].present?
  end
  
  def self.from_omniauth(auth)
    puts auth
#    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
#      user.email = auth.info.email
#      user.password = Devise.friendly_token[0,20]
#      user.last_name = auth.info.name   # assuming the user model has a name
#      user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
#      user.skip_confirmation!
#    end
  end
  
end
