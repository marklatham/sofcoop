class User < ApplicationRecord
  
  has_many :pages
  
  attr_accessor :delete_content
  
  extend FriendlyId
  friendly_id :username, :use => [:slugged, :history]

  VALID_USERNAME_REGEX = /\A[a-zA-Z0-9_]+\z/
  validates :username, length: { maximum: 15, minimum: 1 },
            format: { with: VALID_USERNAME_REGEX }, 
            uniqueness: { case_sensitive: false },
            :allow_nil => false
  
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable # , :omniauthable
  
  def should_generate_new_friendly_id?
    username_changed? || super
  end
  
  validates_presence_of :slug
  after_validation :move_friendly_id_error_to_username

  def move_friendly_id_error_to_username
    errors.add :username, *errors.delete(:friendly_id) if errors[:friendly_id].present?
  end
  
end
