require 'barby/barcode/code_128'
require 'barby/barcode/code_39'
require 'barby/barcode/code_25'
require 'barby/barcode/code_25_interleaved'
require 'barby/barcode/code_25_iata'
require 'barby/outputter/png_outputter'

class CardTemplate < ActiveRecord::Base
  belongs_to :organization
  belongs_to :card_type
  has_many :print_jobs, :dependent => :destroy
  has_many :images, :as => :imageable, :dependent => :destroy
  has_and_belongs_to_many :special_handlings, :dependent => :destroy
  has_one :user_datum, :dependent => :destroy
  has_many :shared_templates, :dependent => :destroy
  belongs_to :master_card_template, class_name: 'CardTemplate'
  has_many :cloned_card_templates, class_name: 'CardTemplate', foreign_key: "master_card_template_id", :dependent => :destroy
  has_many :cards, :dependent => :destroy

  before_save :create_legacy_metadata
  after_save :update_approved_card_template_count
  after_destroy :update_approved_card_template_count
  
  accepts_nested_attributes_for :special_handlings
  accepts_nested_attributes_for :shared_templates, :allow_destroy => true
  validates_associated :shared_templates
  validate :validate_hierarchic
  
  as_enum :status, Draft: 0, Approved: 1, Cloned: 2
  
  scope :card_template_is_all, -> { where('card_templates.status_cd in (0, 1)') }
  scope :card_template_is_draft, -> { where(:status_cd => 0) }
  scope :card_template_is_approved, -> { where(:status_cd => 1) }
  scope :card_template_is_cloned, -> { where(:status_cd => 2)}
  
  def validate_hierarchic
    if shared_templates.present?
      unless Organization.organizations_tree(CardTemplate.find(id), false).collect{|obj| obj.id}.include?(organization.id)
          errors.add(:shared_templates, 'New organization has to be in the organization tree')
      end
    end
  end
  
  def preview_data
    UserDatum.where(card_template_id: self.id).where(list_user_id: nil).first
  end

  # TODO (HR): refactory. Currently don't support CU from ActiveAdmin
  def options_str
    self.options.to_s
  end

  def template_fields_str
    self.template_fields.to_s
  end

  def card_data_str
    self.card_data.to_s
  end

  def add_files(files)
    unless files.is_a?Array
      files = [files]
    end

    files.each do |file|
      new_image = self.images.new(file: file)
      new_image.save!
    end

    self
  end

  def image(user_data_id, side)
    user_data = UserDatum.find_by_id(user_data_id)
    data = (user_data.present?) ? user_data.template_fields_data(self.template_fields) : {}
    
    cdi = self.card_data_image(data)
    data = data.merge(cdi)
    
    card_data = (side.eql?"front") ? self.front_data : self.back_data
    
    # Force use of HTTP for existing images. New ones will be saved and used over HTTP
    card_data = card_data.gsub("https://", "http://")

    # TODO (HR): the code below is to test card template without external access to AWS/S3
    # card_data = convert_image_path_to_base64(card_data)
    
    user_card = Mustache.render(card_data, data)
    user_card
  end
  
  def card_image(card, side)
    data = card.data.nil? ? {} : card.data_hash
    
    cdi = self.card_data_image(data)
    data = data.merge(cdi)
    
    card_data = (side.eql?"front") ? self.front_data : self.back_data
    
    # Force use of HTTP for existing images. New ones will be saved and used over HTTP
    card_data = card_data.gsub("https://", "http://")

    # TODO (HR): the code below is to test card template without external access to AWS/S3
    # card_data = convert_image_path_to_base64(card_data)
    
    user_card = Mustache.render(card_data, data)
    user_card
  end
  
  def card_data_image(data)
    card_data = {}
    
    # Generate Barcodes, QR codes, and others
    self.card_data.each do |card_data_item|
      case card_data_item["type"]
      when "barcode"
        symbology = array_hash_key(card_data_item["data"], "symbology")
        barcode_data = array_hash_key(card_data_item["data"], "barcode")
        # Check for replaceable attributes
        barcode_data = Mustache.render(barcode_data, data)
        begin
          case symbology
          when "code128A"
            barcode = Barby::Code128A.new(barcode_data)
          when "code128B"
            barcode = Barby::Code128B.new(barcode_data)
          when "code128C"
            barcode = Barby::Code128C.new(barcode_data)
          when "code39"
            barcode = Barby::Code39.new(barcode_data)
          when "code39extended"
            barcode = Barby::Code39.new(barcode_data, true)
          when "Code25"
            barcode = Barby::Code25.new(barcode_data)
          when "Code25Interleaved"
            barcode = Barby::Code25Interleaved.new(barcode_data)
          when "Code25IATA"
            barcode = Barby::Code25IATA.new(barcode_data)
          end
        rescue Exception => e
          # TODO (HR): refactory and return error so the card fail instead of priting
        end
        if barcode.present? and barcode.data.present?
          begin
            base64_barcode = "data:image/png;base64," + Base64.encode64(barcode.to_png({xdim: 5})).gsub("\n","")
            card_data.store(card_data_item['token'], base64_barcode)
          rescue
            # TODO (HR): refactory and return error so the card fail instead of priting
          end
        end
      when "qrcode"
        qrcode_data = array_hash_key(card_data_item["data"], "qrcode")
        # Check for replacealbe attributes
        qrcode_data = Mustache.render(qrcode_data, data)
        qr_code = RQRCode::QRCode.new(qrcode_data, level: :l)
        image = qr_code.as_png(module_px_size: 20)
        card_data.store(card_data_item['token'], image.to_data_url)
      when "calculated_date"
        plus = array_hash_key(card_data_item["data"], "plus")
        unit = array_hash_key(card_data_item["data"], "unit") # || "months"
        unit = "months" unless unit.present?
        date_format = array_hash_key(card_data_item["data"], "format") # || "MM-DD-YYYY"
        date_format = "%m/%d/%Y" unless date_format.present?
        date_format.gsub!(/MM/, '%m')
        date_format.gsub!(/DD/, '%d')
        date_format.gsub!(/YYYY/, '%Y')
        
        if user_data.present? && user_data.list_user.present? && user_data.list_user.print_job.present?
          base_date = user_data.list_user.print_job.created_at
        else
          base_date = Time.now
        end
        generated_date = (base_date + plus.to_i.send(unit)).strftime(date_format)
        
        card_data.store(card_data_item['token'], generated_date)
      end
    end

    card_data
  end

  def option_key(key)
    self.options.each do |opt|
      return opt['value'] if opt['key'].eql?key
    end
    ""
  end
  
  def set_option_key(key, value)
    self.options.each do |opt|
      return opt['value'] = value if opt['key'].eql?key
    end
    ""
  end

  def print_options(user_data)
    prt_options = {}
    prt_options_str = "-o fit-to-page "
    self.options.each do |opt|
      case opt["key"]
      when "sides"
        if opt["value"].eql? "double"
          prt_options["PrintBothSides"] = "True"
          prt_options_str += "-o PrintBothSides=True "
        end
      when "color"
        if opt["value"].eql? "colorblack"
          prt_options["SplitRibbon"] = "True"
          prt_options_str += "-o SplitRibbon=True "
        else
          prt_options["SplitRibbon"] = "False"
          prt_options_str += "-o SplitRibbon=False "
        end
      end
    end
    
    data = (user_data.present?) ? user_data.template_fields_data(self.template_fields) : {}
    self.card_data.each do |cd|
      case cd["type"]
      when "magstripe"
        prt_options['Magtrack1'] = Mustache.render(array_hash_key(cd["data"], "track1"), data)
        prt_options['Magtrack2'] = Mustache.render(array_hash_key(cd["data"], "track2"), data)
        prt_options['Magtrack3'] = Mustache.render(array_hash_key(cd["data"], "track3"), data)
        mag_stripe_options_str = "'Magtrack1=%25#{prt_options['Magtrack1']}%3F Magtrack2=%3B#{prt_options['Magtrack2']}%3F Magtrack3=%3B#{prt_options['Magtrack3']}%3F'"
        prt_options_str += "-o #{mag_stripe_options_str}"
      end
    end

    # prt_options
    prt_options_str
  end

  def width
    w = 0
    w = self.card_type.width if self.option_key("orientation").eql? "landscape"
    w = self.card_type.height if self.option_key("orientation").eql? "portrait"
    w
  end

  def height
    h = 0
    h = self.card_type.height if self.option_key("orientation").eql? "landscape"
    h = self.card_type.width if self.option_key("orientation").eql? "portrait"
    h
  end
  
  def image_multiplier
    im = ENV['IMAGE_MULTIPLIER']
    im ||= 5
    im
  end
  
  def image_quality
    iq = ENV['IMAGE_QUALITY']
    iq ||= 1
    iq
  end
  
  def used_fonts(side = "front", raw = false)
    card_side_data = (side.eql?"front") ? self.front_data : self.back_data
    card_fonts = card_side_data.split(',').select { |s| s =~ /fontFamily/ }.uniq.collect{|c| c.split(':')[1].gsub("\"","")}
    if raw
      card_fonts
    else
      Font.where('name in (?)', card_fonts)
    end
  end
  
  def double_sided?
    self.option_key("sides").eql? "double"
  end
  
  def extended_special_handlings
    esh = self.special_handlings.order(id: :desc).to_a
    
    # Slot Punch
    slot_punch_position = self.option_key("slot_punch")
    if slot_punch_position.present? and !slot_punch_position.downcase.eql?"none"
      sp_token = (slot_punch_position.downcase.eql?"short") ? "SPShort" : "SPLong"
      esh << {name: "Slot punch", token: sp_token, description: "Postion: #{slot_punch_position}"}
    end

    # Letter
    letter_id = self.option_key("letter_id")
    letter = LetterTemplate.find(letter_id) if letter_id.present?
    esh << {name: "Letter", token: "L", description: "Uses letter: #{letter.name} and paper type: #{letter.paper_type}"} if letter.present?
    
    esh
  end
  
  def extended_special_handlings_tokens
    esh = self.extended_special_handlings
    esh_token = esh.collect { |item| item[:token] }.join(" ")
  end
  
  def get_hash_object(hash, key, value)
    hash.each do |obj|
      return obj if obj[key].eql? value
    end
    return nil
  end
  
  def self.template_fields_label(tf)
    tf["label"].present? ? CardTemplate.label_sanitizer(tf["label"]) : tf["token"]
  end
  
  def self.label_sanitizer(label)
    label.gsub(/[#~]/, '')
  end

  private

  def create_legacy_metadata
    data_position = 1
    image_position = 0
    image_tokens = ["PHOTO", "SIGNATURE"]
    new_template_fields = []
    self.template_fields.each do |tf|
      case tf["type"]
      when "image"
        if image_position < 2
          new_tf = tf
          new_tf.store("legacy_token", image_tokens[image_position])
          image_position += 1
          new_template_fields << new_tf
        end
      else
        new_tf = tf
        new_tf.store("legacy_token", "DATA_#{data_position}")
        data_position += 1
        new_template_fields << new_tf
      end
    end

    unless new_template_fields.empty?
      self.template_fields = new_template_fields
    end

    true
  end
  
  def array_hash_key(array_hash_obj, key)
    array_hash_obj.each do |obj|
      return obj[key] if obj.key?key
    end
    ""
  end
  
  def convert_image_path_to_base64(card_data)
    self.images.each do |image|
      ext_match = image.file.path.match(/.*\.(.*)/)
      ext = (ext_match.present?) ? ext_match[2] : "png"
      b64 = Base64.encode64(open(image.print_url) { |io| io.read }).gsub("\n","")
      card_data = card_data.gsub(image.print_url, "data:image/#{ext};base64,#{b64}")
    end
    
    card_data
  end

  def update_approved_card_template_count
    if organization.present?
      organization.update_attribute(:approved_card_template_count, organization.card_templates.where("status_cd = 1").count)
    end
  end

end
