class Cost < ActiveRecord::Base
  belongs_to :costable, :polymorphic => true
  belongs_to :organization
  has_many :transaction_items
  
  validate :validate_range_low_and_range_high

  attr_accessor :costable_item
  def costable_item
    costable.present? ? "#{costable.class.to_s}-#{costable.id}" : ""
  end
  
  def costable_item_label
    costable.present? ? "#{costable.class.to_s} - #{costable.name}" : ""
  end
  
  def costable_item=(costable_data)
    if costable_data.present?
      costable_data = costable_data.split('-')
      self.costable_type = costable_data[0]
      self.costable_id = costable_data[1]
    end
  end

  def cost_entity
    if organization.present?
      "Organization based"
    else
      "Default"
    end
  end
  
  def quantity
    "#{self.range_low} - #{self.range_high}"
  end
  
  def self.all_cost_items
    begin
      CardType.all + ShippingProvider.all + CardOption.all + SpecialHandling.all
    rescue
      []
    end
  end

  def self.find_cost(organization, item, quantity)
    cost_item = Cost.where(organization_id: organization.id).where(costable_id: item.id).where(costable_type: item.class.to_s)
    if cost_item.empty?
      # Look for costs in the parent organization
      parent = organization.parent_organization
      while !parent.nil?
        puts "Looking for cost in parent #{parent.name}"
        cost_item = Cost.where(organization_id: parent.id).where(costable_id: item.id).where(costable_type: item.class.to_s)
        
        break if cost_item.present?
        parent = parent.parent_organization
      end
    end

    if cost_item.empty?
      cost_item =Cost.where(organization_id: nil).where(costable_id: item.id).where(costable_type: item.class.to_s)
    end
    
    cost = cost_item.where("range_low <= ? and range_high >= ?", quantity, quantity)
    
    # In case there is no cost within range_low/high & quantity
    unless cost.present?
      # In case quantity is bigger than the biggest range_high
      cost = cost_item.where("range_high < ?", quantity).order(range_high: :desc)
    end

    cost.first
  end
    
  protected

  def validate_range_low_and_range_high
    # validate range_low <= range high
    if self.range_low > self.range_high
      errors.add(:range_low, "has to be bigger than higher range")
    end

    # validate range (low) instersection
    cost_item = Cost.find_value_in_range(self.organization_id, self.costable_id, self.costable_type, self.range_low)
    if cost_item.present?
      cost = cost_item.first
      unless cost.id.eql?self.id
        errors.add(:range_low, "Lower range is inside another range. Cost (Id: #{cost.id}) (Lower: #{cost.range_low}) (Higher: #{cost.range_high})")
      end
    end

    # validate range (high) instersection
    cost_item = Cost.find_value_in_range(self.organization_id, self.costable_id, self.costable_type, self.range_high)
    if cost_item.present?
      cost = cost_item.first
      unless cost.id.eql?self.id
        errors.add(:range_high, "Higher range is inside another range. Cost (Id: #{cost.id}) (Lower: #{cost.range_low}) (Higher: #{cost.range_high})")
      end
    end
    
    # TODO (HR): validate range gaps
    
  end
  
  def self.find_value_in_range(organization_id, costable_id, costable_type, value)
    cost_item = Cost.where(organization_id: organization_id).where(costable_id: costable_id).where(costable_type: costable_type).where("range_low <= ? and range_high >= ?", value, value)
    cost_item
  end
  
end
