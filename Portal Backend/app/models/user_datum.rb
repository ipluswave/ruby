class UserDatum < ActiveRecord::Base
  belongs_to :user
  belongs_to :list_user
  belongs_to :card_template
  has_one :print_job, through: :list_user
  belongs_to :card

  as_enum :status, Created: 0, Printed: 1, Failed: 2

  ransacker :DATA_1 do |parent|
    Arel::Nodes::InfixOperation.new(
      '->>', parent.table[:data], Arel::Nodes.build_quoted('DATA_1'))
  end
  ransacker :DATA_2 do |parent|
    Arel::Nodes::InfixOperation.new(
      '->>', parent.table[:data], Arel::Nodes.build_quoted('DATA_1'))
  end
  ransacker :DATA_3 do |parent|
    Arel::Nodes::InfixOperation.new(
      '->>', parent.table[:data], Arel::Nodes.build_quoted('DATA_1'))
  end
      
  def self.from_params(params, from_wsdl)
    if from_wsdl
      user_data = [{
        "user_data"=>{
          "data" => params
        }}]
    else
      user_data = JSON.parse(params)
    end
    user_data
  end
  
  def template_fields_data(template_fields)
    formatted_data = self.data
    if self.data["token"].present? or self.data["CardRefNum"].present?
      new_data = {}
      template_fields.each do |tf|
        if tf["legacy_token"].present?
          if self.data[tf["legacy_token"]].present?
            if tf["type"].eql?"image" and !self.data[tf["legacy_token"]].start_with?("http")
              new_data.store(tf["token"], "data:image/jpeg;base64,#{data[tf['legacy_token']]}")
            else
              new_data.store(tf["token"], self.data[tf["legacy_token"]])
            end
          end
        else
          if self.data[tf["token"]].present?
            if tf["type"].eql?"image" and !self.data[tf["token"]].start_with?("http")
              new_data.store(tf["token"], "data:image/jpeg;base64,#{data[tf['token']]}")
            else
              new_data = new_data.merge(tf)
            end
          end
        end
      end
      formatted_data = new_data
    end

    formatted_data
  end
  
  def to_wsdl_params(params_hash)
    (1..50).each { |i|
      template_field_item = self.card_template.get_hash_object(self.card_template.template_fields, "legacy_token", "DATA_#{i}")
      params_hash["DATA_#{i}"] = nil unless template_field_item.present?
      params_hash["DATA_#{i}"] = self.data[template_field_item["token"]] if template_field_item.present?
    }
    template_field_item = self.card_template.get_hash_object(self.card_template.template_fields, "legacy_token", "PHOTO")
    params_hash["PHOTO"] = nil unless template_field_item.present?
    if template_field_item.present?
      if self.data[template_field_item["token"]].present? and self.data[template_field_item["token"]].start_with?("http")
        image = Base64.encode64(Net::HTTP.get(URI(self.data[template_field_item["token"]])))
      else
        image = self.data[template_field_item["token"]]
      end
      params_hash["PHOTO"] = image
    end
    template_field_item = self.card_template.get_hash_object(self.card_template.template_fields, "legacy_token", "SIGNATURE")
    params_hash["SIGNATURE"] = nil unless template_field_item.present?
    if template_field_item.present?
      if self.data[template_field_item["token"]].present? and self.data[template_field_item["token"]].start_with?("http")
        image = Base64.encode64(Net::HTTP.get(URI(self.data[template_field_item["token"]])))
      else
        image = self.data[template_field_item["token"]]
      end
      params_hash["SIGNATURE"] = image
    end
    params_hash
  end
  
  def fix_data
    new_data_hash = {} 
    self.data.each { |k,v|
      next unless v.present?
      if v.is_a?String
        new_data_hash[k] = v.gsub(/\"/, "''")
      else
        new_data_hash[k] = v
      end
    }
    self.data = new_data_hash
    self.save!
  end
  
  def self.mock_wsdl_user_params(card_template, params_hash)
    (1..50).each { |i|
      # template_field_item = card_template.get_hash_object(card_template.template_fields, "legacy_token", "DATA_#{i}")
      # params_hash["DATA_#{i}"] = nil unless template_field_item.present?
      params_hash["DATA_#{i}"] = "Data #{i}" # if template_field_item.present?
    }

    image = Base64.encode64(Net::HTTP.get(URI("http://s3-us-west-2.amazonaws.com/instantcard-core/sample/photo.jpg")))
    params_hash["PHOTO"] = image

    image = Base64.encode64(Net::HTTP.get(URI("http://s3-us-west-2.amazonaws.com/instantcard-core/sample/signature.jpg")))
    params_hash["SIGNATURE"] = image

    params_hash
  end
  
end
