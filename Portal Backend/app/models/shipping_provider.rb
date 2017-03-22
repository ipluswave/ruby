class ShippingProvider < ActiveRecord::Base
  has_many :costs, :as => :costable
  
end
