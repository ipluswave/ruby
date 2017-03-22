class SharedTemplate < ActiveRecord::Base
  belongs_to :organization
  belongs_to :card_template
  belongs_to :clone_card_template, :class_name => "CardTemplate"

  validates :organization_id, presence: true, :uniqueness => {:scope => :card_template_id}
  validate :validate_hierarchic

  def validate_hierarchic
    unless Organization.organizations_tree(CardTemplate.find(card_template_id), false).collect{|obj| obj.id}.include?(organization_id)
      errors.add(:shared_templates, "Organization with id=" + organization_id.to_s + " not found in organization tree")
    end
  end
  
  def make_it_unique
    return [false, "This shared template (ID: #{self.id}) is already unique with ID #{self.clone_card_template_id}"] if self.clone_card_template_id.present?
    return [false, "Invalid card template for this shared template (ID: #{self.id})"] unless self.card_template_id.present?
    return [false, "Invalid organization for this shared template (ID: #{self.id})"] unless self.organization_id.present?

    ct = CardTemplate.new(status_cd: 2, master_card_template_id: self.card_template_id)
    ct.name = "#{self.card_template.name} - Clone"
    ct.save!
    
    self.clone_card_template_id = ct.id
    self.save!
    
    [true, "Shared template (ID: #{self.id}) is now unique with ID #{ct.id}"]
  end
end
