class CardPrintHistory < ActiveRecord::Base
  belongs_to :card
  belongs_to :user_datum
end
