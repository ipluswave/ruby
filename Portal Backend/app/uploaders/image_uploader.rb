# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog
  
  # TODO (HR): this should remove it from S3
  # after :remove, :delete_empty_upstream_dirs

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if model.present?
      "#{Rails.env}/#{base_store_dir}/#{model.id}"
    elsif @cache_id.present?
      "#{Rails.env}/uploads/preview/#{@cache_id}"
    else
      nil
    end
  end
  
  def base_store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}"
  end
  
  # TODO (HR): this should remove it from S3
  # def delete_empty_upstream_dirs
  #   path = ::File.expand_path(store_dir, root)
  #   Dir.delete(path) # fails if path not empty dir
  # 
  #   path = ::File.expand_path(base_store_dir, root)
  #   Dir.delete(path) # fails if path not empty dir
  # rescue SystemCallError => e
  #   Rails.logger.error("[ImageUploader::delete_empty_upstream_dirs] Exception: #{e.message} ")
  #   true # nothing, the dir is not empty
  # end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg image/jpg image/jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end