class Printer < ActiveRecord::Base
  belongs_to :workstation
  has_one :site, through: :workstation

  validates :name, format: { with: /\A[a-zA-Z0-9\-_]+\z/, message: "only allows letters, numbers, - (hyphen), and _ (underscore)" }
      
  has_and_belongs_to_many :card_types
  accepts_nested_attributes_for :card_types
  
  def last_card_type
    return nil unless self.workstation.present?
    
    # Type_cd: 0 as in Normal, 1 as in Re-print
    # Status_cd: 2 as in InProgress, 3 as in Finished, 4 as in Failed
    self.workstation.print_jobs.where('type_cd = 0 or type_cd = 1').where('status_cd >= 2 or status_cd < 4').last.card_template.card_type
  end
  
  def last_card_type_name
    return "" unless self.workstation.present?
    
    begin
      # Type_cd: 0 as in Normal, 1 as in Re-print
      # Status_cd: 2 as in InProgress, 3 as in Finished, 4 as in Failed
      name = self.workstation.print_jobs.where('type_cd = 0 or type_cd = 1').where('status_cd >= 2 or status_cd < 4').last.card_template.card_type.name
    rescue
      name = ""
    end

    name
  end

  
  def self.card_printers
    Printer.where(print_label: false).where(print_letter: false)
  end
  
end
