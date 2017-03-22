class FinancialTransaction < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user
  has_one :financial_transaction_type, :through => :financial_transaction_sub_type
  belongs_to :financial_transaction_sub_type
  has_many :transaction_items, :dependent => :destroy
  belongs_to :print_job

  as_enum :operation, Credit: 0, Debit: 1

  monetize :credit, :allow_nil => true
  monetize :debit, :allow_nil => true

  attr_accessor :skip_callbacks
  validates :organization, presence: true
  validates :financial_transaction_sub_type, presence: true
  validate :credit_debit_values, on: :create
  validate :determine_running_balance, on: :create
  after_create :execute_fund_operation
  
  def short_description
    return description[0..25] + '...' if description.length > 26
    description
  end

  def self.break_value_in_credit_debit
    FinancialTransaction.find_each(batch_size: 5000) do |ft|
      case ft.financial_transaction_type.name
      # when 'Credit'
      # Nothing to do
      when 'Debit'
        ft.debit = ft.credit
        ft.credit = 0
      end
      ft.save!
    end
  end
  
  private
  
  def execute_fund_operation
    return true if self.skip_callbacks
    organization_to_be_charged = self.organization.who_pays_for_my_jobs
    organization_to_be_charged.balance = FinancialTransaction.organization_new_balance(self)

    if self.organization.id.eql?organization_to_be_charged.id
      organization_to_be_charged.last_financial_transaction = self.created_at
    else
      self.organization.last_financial_transaction = self.created_at
      self.organization.save!
    end

    organization_to_be_charged.save!
  end
  
  def determine_running_balance
    return true if self.skip_callbacks
    return false if !self.organization.present? or !self.financial_transaction_sub_type.present?
    new_balance = FinancialTransaction.organization_new_balance(self)
    if new_balance <= (self.organization.who_pays_for_my_jobs.overdraft*-1)
      Rails.logger.error("Balance of $#{new_balance.to_money} below overdraft. #{self.organization.who_pays_for_my_jobs.name} maximum overdraft is $#{self.organization.who_pays_for_my_jobs.overdraft}")
    end

    self.balance = new_balance unless self.balance.present?
  end
  
  def credit_debit_values
    return false if !self.organization.present? or !self.financial_transaction_sub_type.present?

    case self.financial_transaction_type.name
    when 'Debit'
      errors.add(:credit, "is not applicable for Debit transactions") if self.credit.present? and !self.credit.eql?0
      # Legacy system contains invalid financial transactions, but used for permanent notation in the DB
      errors.add(:debit, "value should be different than zero to make a difference") if !self.debit.present? or self.debit < 0
    when 'Credit'
      errors.add(:debit, "is not applicable for Credit transactions") if self.debit.present? and !self.debit.eql?0
      # Legacy system contains invalid financial transactions, but used for permanent notation in the DB
      errors.add(:credit, "value should be different than zero to make a difference") if !self.credit.present? or self.credit < 0
    end
    
  end

  def self.organization_new_balance(transaction)
    return 0 if transaction.errors.count > 0
    new_balance = transaction.organization.who_pays_for_my_jobs.balance

    # case transaction.operation_cd
    case transaction.financial_transaction_sub_type.financial_transaction_type.transaction_type
    when 1
      # Credit
      new_balance = new_balance + transaction.credit
    when 2
      # Debit
      new_balance = new_balance - transaction.debit
    end
    
    new_balance
  end

end
