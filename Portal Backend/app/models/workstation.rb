class Workstation < ActiveRecord::Base
  belongs_to :site
  has_many :printers
  has_many :print_jobs
  
  as_enum :status, Inactive: 0, Active: 1, 'Out of commission' => 2

  scope :workstation_is_active, -> { where(:status_cd => 1) }
end
