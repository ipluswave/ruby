module Legacy
  class LegacyBase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection "legacy".to_sym

    def self.set_log_level(current_level, new_level)
      val = [current_level]
      if new_level.is_a?Symbol
        val << log_level_to_integer(new_level)
      else
        val << new_level
      end
      val.max
    end
    
    def self.log_level_to_integer(level)
      case level
      when :migration_log_ok
        0
      when :migration_log_warning
        1
      when :migration_log_error
        2
      # when :migration_log_undefined
      else
        3
      end
    end
  end
end
