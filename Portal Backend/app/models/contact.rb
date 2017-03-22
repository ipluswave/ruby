class Contact < ActiveRecord::Base
  belongs_to :organization
  has_many :addresses

  validates :full_name, presence: true
  validates :email, presence: true
  validates :phone_number, presence: true
  
end
