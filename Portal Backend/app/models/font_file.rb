require 'carrierwave/orm/activerecord'

class FontFile < ActiveRecord::Base
  belongs_to :fontfileable, :polymorphic => true

  def print_url
    self.file.url.gsub("https://", "http://")
  end

  attr_accessor :fontfileable_item
  def fontfileable_item
    fontfileable.present? ? "#{fontfileable.class.to_s}-#{fontfileable.id}" : ""
  end

  def fontfileable_item=(fontfileable_data)
    if fontfileable_data.present?
      fontfileable_data = fontfileable_data.split('-')
      self.fontfileable_type = fontfileable_data[0]
      self.fontfileable_id = fontfileable_data[1]
    end
  end

  mount_uploader :file, FontUploader
end
