class User < ApplicationRecord
  rolify

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable # , :omniauthable

  VALID_USERNAME_REGEX = /\A[a-zA-Z0-9_]+\z/
  validates :username, length: { maximum: 15 },
            format: { with: VALID_USERNAME_REGEX }, 
            uniqueness: { case_sensitive: false }
  
end
