class FinancialTransactionType < ActiveRecord::Base
  has_many :financial_transaction_sub_types
  has_many :financial_transaction
  
end
