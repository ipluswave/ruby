class CardType < ActiveRecord::Base
  has_many :card_templates
  has_many :costs, :as => :costable, :dependent => :destroy
  has_and_belongs_to_many :printers
  has_many :legacy_card_types
  has_and_belongs_to_many :organizations, :join_table => :organizations_card_types
  
end
