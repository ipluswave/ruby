class SpecialHandling < ActiveRecord::Base
  has_and_belongs_to_many :card_templates
  has_many :costs, :as => :costable, :dependent => :destroy
  belongs_to :organization

  scope :global, -> { where(organization_id: nil) }

end
