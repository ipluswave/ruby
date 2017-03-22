class OffsetFinancialTransactionId < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE financial_transactions_id_seq RESTART WITH 200000")
  end
end
