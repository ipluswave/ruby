class LegacyCardType < ActiveRecord::Base
  belongs_to :card_type

  def has_extras?
    self.double_sided? or self.slot_punch? or self.overlay? or self.color_color? or self.drop_ship? or self.grommet? or self.hole_punch?
  end
end
