class Site < ActiveRecord::Base
  has_many :workstations
  has_many :printers, :through => :workstations
  
end
