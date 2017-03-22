class Font < ActiveRecord::Base
  has_and_belongs_to_many :organizations
  has_many :font_files, :as => :fontfileable, :dependent => :destroy

  scope :global, -> { where(global: true) }
end
