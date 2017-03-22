class User < ActiveRecord::Base
  rolify

  accepts_nested_attributes_for :users_roles

  validates :pin, presence: true, :if => :has_admin_role?
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable

  before_create :assign_default_role

  belongs_to :organization

  protected

  def has_admin_role?
    # self.roles.collect{ |role| role.name }.include?('admin')
    
    # Using a methog provided by rolify gem
    self.has_role? :admin
  end
  
  def assign_default_role
    add_role(:individual) if self.roles.blank?
  end
end
