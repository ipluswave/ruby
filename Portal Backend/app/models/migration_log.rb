class MigrationLog < ActiveRecord::Base
  belongs_to :migration_task
  belongs_to :organization

  as_enum :status, migration_log_ok: 0, migration_log_warning: 1, migration_log_error: 2, migration_log_undefined: 3

  default_scope { order(id: :asc) }

  def short_message(n=32)
    return message[0..n] + '...' if message.length > (n+1)
    message
  end
  
  def long_message
    return message[0..256] + '...' if message.length > 257
    message
  end
  
  def self.status_to_symbol(status)
    return :migration_log_error if status.eql?"error"
    return :migration_log_warning if status.eql?"warning"
    return :migration_log_warning if status.eql?"migrating" # Consider it warning until the bug is fixed
    return :migration_log_ok if status.eql?"ok" or status.eql?"success"
    return :migration_log_undefined
  end
end
