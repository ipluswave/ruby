class Card < ActiveRecord::Base
  belongs_to :organization
  belongs_to :card_template
  has_many :card_images, :as => :imageable, :dependent => :destroy

  def add_file(file)
    card_image = self.card_images.new(file)
    card_image.save!

    self
  end
  
  def image(side)
    self.card_template.card_image(self, side)
  end
  
  def data_hash
    to_ret = {}
    data.each do |item|
      to_ret[item["token"]] = item["value"]
    end
    
    to_ret
  end
end
