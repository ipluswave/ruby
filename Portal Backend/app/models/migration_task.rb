class MigrationTask < ActiveRecord::Base
  belongs_to :user
  has_many :migration_logs
  has_and_belongs_to_many :organizations

  validates_numericality_of :from_organization_id
  validates_numericality_of :to_organization_id, :greater_than_or_equal_to => :from_organization_id
    
  as_enum :status, Created: 0, Running: 1, Finished: 2, Failed: 3
  
  def self.default_scope
    order(id: :desc)
  end
  
  def total_migrated
    self.organizations.count
  end
  
  def name
    "Migration ##{self.id}"
  end
  
  def notify
    # TODO (HR): need MailGun credentials
    # # First, instantiate the Mailgun Client with your API key
    # mg_client = Mailgun::Client.new
    # 
    # # Define your message parameters
    # message_params =  { from: 'admin@instantcard.net',
    #                     to:   'helio.cola@gmail.com',
    #                     subject: "#{name} has finished",
    #                     text:    "Range: #{self.from_organization_id} to #{self.to_organization_id}"
    #                   }
    # 
    # begin
    #   # Send your message through the client
    #   mg_client.send_message 'instantcard.net', message_params
    # rescue Exception => e
    # end
  end

  def self.log_error_message(task, organization, message, level = :migration_log_undefined)
    Rails.logger.error(message)
    if task.present?
      new_task_log = task.migration_logs.new
      new_task_log.organization_id = organization.id if organization.present?
      new_task_log.message = message
      case level
      when :migration_log_ok
        new_task_log.migration_log_ok!
      when :migration_log_warning
        new_task_log.migration_log_warning!
      when :migration_log_error
        new_task_log.migration_log_error!
      # when :migration_log_undefined
      else
        new_task_log.migration_log_undefined!
      end
      new_task_log.save!
    end
  end

end
