class FinancialTransactionSubType < ActiveRecord::Base
  belongs_to :financial_transaction_type
  has_many :financial_transaction
  
end
