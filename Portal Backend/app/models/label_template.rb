class LabelTemplate < ActiveRecord::Base
  belongs_to :organization

  as_enum :type, Address_On_File: 0, WSDL_Api_Format: 1
  
  scope :global, -> { where(organization_id: nil) }

end
