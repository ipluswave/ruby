class Address < ActiveRecord::Base
  belongs_to :organization
  belongs_to :contact

  validates :address1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true
  validates :country, presence: true

  after_save :reset_primary_address
  
  def to_print
    label_template = self.organization.label_templates.Address_On_Files.first
    label_template ||= LabelTemplate.global.Address_On_Files.first
    if label_template.present?
      from_address = Mustache.render(label_template.template, self)
      to_address = Mustache.render(label_template.to_address, self)
      [from_address, to_address]
    else
      # Fallback of a fallback
      ["", "#{self.organization_name}\n#{self.address1} #{self.address2}\n#{self.city}, #{self.state} #{self.zip_code}\n#{self.country}"]
    end
  end
  
  def label_organization_name
    self.organization_name[0..40]
  end

  def reset_primary_address
    if self.primary
      old_primary_address = Address.where('organization_id = :organization_id AND "primary" = true AND id != :id', organization_id: self.organization_id, id: self.id).first
      if old_primary_address.present?
        old_primary_address.primary = false
        old_primary_address.save
      end
    end
  end
end
