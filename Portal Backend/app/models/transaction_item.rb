class TransactionItem < ActiveRecord::Base
  belongs_to :financial_transaction
  belongs_to :cost
  
end
