class ListUser < ActiveRecord::Base
  belongs_to :print_job
  has_many :user_datum, :dependent => :destroy

  def total_users
    self.user_datum.count
  end
  
  def add_users(params, from_wsdl)
    users_data = UserDatum.from_params(params, from_wsdl)
    users_data.each do |ua|
      ud = self.user_datum.new(ua["user_data"])
      if from_wsdl
        if ud.data["CardRefNum"].blank?
          ud.card_template_id = self.print_job.card_template_id
        else
          ud.card_template_id = ud.data["CardRefNum"]
        end
      else
        ud.card_template_id = self.print_job.card_template_id if self.print_job.card_template_id.present?
      end
      ud.save!
    end
  end

  def add_cards(cards)
    cards.each do |card|
      unless self.user_datum.where(card_id: card.id).first
        ud = self.user_datum.new(
            card_id: card.id,
            card_template_id: card.card_template_id
        )
        ud.save!
      end
    end
  end

end
