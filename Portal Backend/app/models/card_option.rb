class CardOption < ActiveRecord::Base
  has_many :costs, :as => :costable, :dependent => :destroy

  def name
    item = "#{self.element} with #{self.key}"
    item += "=#{self.value}" if self.value.present?
    item
  end
  
  def self.element_options
    ["options", "card_data"]
  end
  
  def self.key_options
    ["sides", "orientation", "color", "letter_id", "magstripe", "barcode", "qrcode"]
  end
  
  def self.value_options
    ["single", "double", "landscape", "portrait", "colorcolor", "colorblack", ""]
  end
end
