class IcardController < ApplicationController
  soap_service namespace: 'urn:ICard'

  soap_action "Auth",
              :args   => { :email => :string, :CompanyPIN => :string, :password => :string },
              :return => { :return => :string }
  def Auth
    user = user_params_with_password if params[:password].present?
    user ||= user_params if params[:CompanyPIN].present? and !params[:password].present?

    if !user.present?
      # 02: not found
      response = "02"
    elsif user.present? and user.organization.NewSystem?
      # 01: authenticated and organization Migrated
      response = "01"
    elsif user.present? and user.organization.Legacy?
      # 03: user present and organization hasn't been migrated
      response = "03"
    # else
    #   # TODO (HR): this query requires user_params_with_password and user_params
    #   # to return a user with mismatch pin or password
    #   # 04: 
    end
    
    Rails.logger.info ("[WSDL:Auth] Response: #{response}")
    render :soap => { :return => response }
  end

  soap_action "LogIn",
              :args   => { :email => :string, :CompanyPIN => :string },
              :return => { :return => :string }
  def LogIn
    response = user_params.present? ? "01" : "02"
    Rails.logger.info ("[WSDL:LogIn] Response: #{response}")
    render :soap => { :return => response }
  end
  
  # Create a new Job
  # Return value: code and the JobId
  soap_action "SetJob",
              :args   => { 
                :email => :string, 
                :CompanyPIN => :string, 
                :CardRefNum => :integer,
                :NumOfCards => :integer},
              :return => { :return => :string }

  # Create a new Job with a Shipping method provider
  # Return value: code and the JobId
  soap_action "SetJobShip",
              :args   => { 
                :email => :string, 
                :CompanyPIN => :string, 
                :CardRefNum => :integer,
                :NumOfCards => :integer,
                :ShipMethod => :integer},
              :to => "SetJob",
              :return => { :return => :string }
  def SetJob
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:SetJob] Response: 02")
      render :soap => { :return => "02" }
      return
    end
    
    if params[:NumOfCards] <= 0
      Rails.logger.info ("[WSDL:SetJob] Response: 03")
      render :soap => { :return => "03" }
      return
    end

    card_template = user_card_template_validation(user)
    unless card_template.present?
      Rails.logger.info ("[WSDL:SetJob] Response: 05")
      render :soap => { :return => "05" }
      return
    end
    
    new_job = PrintJob.from_wsdl(params, user.organization.id, card_template)
    unless new_job.present?
      Rails.logger.info ("[WSDL:SetJob] Response: 11")
      render :soap => { :return => "11" }
      return
    end
    
    if new_job.shipping_provider.present?
      unless new_job.has_balance_for_job(params[:NumOfCards])
        Rails.logger.info ("[WSDL:SetJob] Response: 07")
        render :soap => { :return => "07" }
        return
      end
    end
    
    new_job.save
    response = "01,Token=#{new_job.id}"

    Rails.logger.info ("[WSDL:SetJob] Response: #{response}")
    render :soap => { :return => response }
  end

  soap_action "SetJobAddress",
              :args => {
                :email => :string,
                :CompanyPIN => :string,
                :CardRefNum => :integer,
                :NumOfCards => :integer, 
                :Title => :string, 
                :FirstName => :string, 
                :LastName => :string,
                :FullName => :string, 
                :Add1 => :string, 
                :Add2 => :string, 
                :Add3 => :string, 
                :Add4 => :string,
                :Postcode => :string, 
                :PaymentRef => :string, 
                :PrintInvoice => :integer, 
                :NumOfItems => :integer,
                :Num1 => :integer, 
                :Des1 => :string, 
                :Cost1 => :double, 
                :Num2 => :integer, 
                :Des2 => :string, 
                :Cost2 => :double,
                :Num3 => :integer, 
                :Des3 => :string, 
                :Cost3 => :double, 
                :Num4 => :integer, 
                :Des4 => :string, 
                :Cost4 => :double,
                :Num5 => :integer, 
                :Des5 => :string, 
                :Cost5 => :double, 
                :Num6 => :integer, 
                :Des6 => :string, 
                :Cost6 => :double,
                :Num7 => :integer, 
                :Des7 => :string, 
                :Cost7 => :double, 
                :Num8 => :integer, 
                :Des8 => :string, 
                :Cost8 => :double,
                :Num9 => :integer, 
                :Des9 => :string, 
                :Cost9 => :double, 
                :Num10 => :integer, 
                :Des10 => :string, 
                :Cost10 => :double,
                :PrintLetter => :integer, 
                :LetterText => :string
              },
              :return => {:return => :string}

  soap_action "SetJobAddressShip",
              :args => {
                :email => :string,
                :CompanyPIN => :string,
                :CardRefNum => :integer,
                :NumOfCards => :integer, 
                :Title => :string, 
                :FirstName => :string, 
                :LastName => :string,
                :FullName => :string, 
                :Add1 => :string, 
                :Add2 => :string, 
                :Add3 => :string, 
                :Add4 => :string,
                :Postcode => :string, 
                :PaymentRef => :string, 
                :PrintInvoice => :integer, 
                :NumOfItems => :integer,
                :Num1 => :integer, 
                :Des1 => :string, 
                :Cost1 => :double, 
                :Num2 => :integer, 
                :Des2 => :string, 
                :Cost2 => :double,
                :Num3 => :integer, 
                :Des3 => :string, 
                :Cost3 => :double, 
                :Num4 => :integer, 
                :Des4 => :string, 
                :Cost4 => :double,
                :Num5 => :integer, 
                :Des5 => :string, 
                :Cost5 => :double, 
                :Num6 => :integer, 
                :Des6 => :string, 
                :Cost6 => :double,
                :Num7 => :integer, 
                :Des7 => :string, 
                :Cost7 => :double, 
                :Num8 => :integer, 
                :Des8 => :string, 
                :Cost8 => :double,
                :Num9 => :integer, 
                :Des9 => :string, 
                :Cost9 => :double, 
                :Num10 => :integer, 
                :Des10 => :string, 
                :Cost10 => :double,
                :PrintLetter => :integer, 
                :LetterText => :string, 
                :ShipMethod => :integer
              },
              :to => "SetJobAddress",
              :return => {:return => :string}
  def SetJobAddress
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:SetJobAddress] Response: 02")
      render :soap => { :return => "02" }
      return
    end

    if params[:NumOfCards] <= 0
      Rails.logger.info ("[WSDL:SetJobAddress] Response: 03")
      render :soap => { :return => "03" }
      return
    end

    card_template = user_card_template_validation(user)
    unless card_template.present?
      Rails.logger.info ("[WSDL:SetJobAddress] Response: 05")
      render :soap => { :return => "05" }
      return
    end

    new_job = PrintJob.from_wsdl(params, user.organization.id, card_template)
    unless new_job.present?
      Rails.logger.info ("[WSDL:SetJobAddress] Response: 11")
      render :soap => { :return => "11" }
      return
    end
    
    unless new_job.has_balance_for_job(params[:NumOfCards])
      Rails.logger.info ("[WSDL:SetJob] Response: 07")
      render :soap => { :return => "07" }
      return
    end
    
    new_job.append_context(new_job.organization.letter_replaceable_attributes)
    
    new_job.save
    response = "01,Token=#{new_job.id}"
    Rails.logger.info ("[WSDL:SetJobAddress] Response: #{response}")
    
    render :soap => { :return => response }
  end

  soap_action "PreviewCard",
              :args => {
                :email => :string, 
                :CompanyPIN => :string, 
                :CardRefNum => :integer, 
                :CardSide => :integer,
                :CardWidth => :integer, 
                :DATA_1 => :string, 
                :DATA_2 => :string, 
                :DATA_3 => :string,
                :DATA_4 => :string, 
                :DATA_5 => :string, 
                :DATA_6 => :string, 
                :DATA_7 => :string, 
                :DATA_8 => :string,
                :DATA_9 => :string, 
                :DATA_10 => :string, 
                :DATA_11 => :string, 
                :DATA_12 => :string, 
                :DATA_13 => :string,
                :DATA_14 => :string, 
                :DATA_15 => :string, 
                :DATA_16 => :string, 
                :DATA_17 => :string, 
                :DATA_18 => :string,
                :DATA_19 => :string, 
                :DATA_20 => :string, 
                :DATA_21 => :string, 
                :DATA_22 => :string, 
                :DATA_23 => :string,
                :DATA_24 => :string, 
                :DATA_25 => :string, 
                :DATA_26 => :string, 
                :DATA_27 => :string, 
                :DATA_28 => :string,
                :DATA_29 => :string, 
                :DATA_30 => :string,
                :DATA_31 => :string, 
                :DATA_32 => :string, 
                :DATA_33 => :string,
                :DATA_34 => :string, 
                :DATA_35 => :string, 
                :DATA_36 => :string, 
                :DATA_37 => :string, 
                :DATA_38 => :string,
                :DATA_39 => :string,
                :DATA_40 => :string, 
                :DATA_41 => :string, 
                :DATA_42 => :string, 
                :DATA_43 => :string,
                :DATA_44 => :string, 
                :DATA_45 => :string, 
                :DATA_46 => :string, 
                :DATA_47 => :string, 
                :DATA_48 => :string, 
                :DATA_49 => :string,
                :DATA_50 => :string, 
                :PHOTO => :string,
                :SIGNATURE => :string, 
              },
              :return => { :return => :string }
  def PreviewCard
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:PreviewCard] Response: 02")
      render :soap => { :return => "02" }
      return
    end
    
    card_template = user_card_template_validation(user)
    unless card_template.present?
      Rails.logger.info ("[WSDL:PreviewCard] Response: 05")
      render :soap => { :return => "05" }
      return
    end
    
    if params[:CardSide].eql?1 and card_template.option_key("sides").eql?"single"
      # Card Template only have one side
      card_path = "#{Rails.root.to_s}/public/preview/white.png"
      preview_base_64 = Base64.encode64(open(card_path).to_a.join)
      Rails.logger.info ("[WSDL:PreviewCard] Response: single sided don't have the back side")
      render :soap => { :return => preview_base_64 }
      return
    end
    
    # TODO (HR): Refactory to avoid creating this record to improve preview speed
    preview_data = UserDatum.from_params(params, true)
    ud = UserDatum.new(preview_data.first["user_data"])
    ud.fix_data
    ud.save!

    card_side = ["front", "back"][params[:CardSide]]
    card_url = "#{ENV['preview_root']}/card_templates/#{card_template.id}/image/#{ud.id}/#{card_side}/preview"
    # TODO (HR): refactory it. The use of this variable is deprecated
    card_path = "" # "#{Rails.root.to_s}/tmp/preview/card-#{card_template.id}-#{params[:CardSide]}-#{ud.id}.jpeg"

    begin
      screenshot = Screenshot.new
      # TODO (HR): refactory the +1 for preview width and height
      ret = screenshot.capture(card_url, card_path, card_template.width+1, card_template.height+1, true)
      preview_base_64 = ret[1]
      screenshot.reset_session
    rescue Exception => e
      Rails.logger.error("Unable to capture card image preview. Message: #{e.message}")
      preview_base_64 = ""
    end
    
    # Delete UD
    ud.destroy
    
    # Rails.logger.info ("[WSDL:PreviewCard] Response: Base64 image (not printed)")
    render :soap => { :return => preview_base_64 }
  end

  soap_action "SetStaffData",
              :args   => { 
                :token => :string, 
                :DATA_1 => :string, 
                :DATA_2 => :string, 
                :DATA_3 => :string,
                :DATA_4 => :string, 
                :DATA_5 => :string, 
                :DATA_6 => :string, 
                :DATA_7 => :string, 
                :DATA_8 => :string,
                :DATA_9 => :string, 
                :DATA_10 => :string, 
                :DATA_11 => :string, 
                :DATA_12 => :string, 
                :DATA_13 => :string,
                :DATA_14 => :string, 
                :DATA_15 => :string, 
                :DATA_16 => :string, 
                :DATA_17 => :string, 
                :DATA_18 => :string,
                :DATA_19 => :string, 
                :DATA_20 => :string, 
                :DATA_21 => :string, 
                :DATA_22 => :string, 
                :DATA_23 => :string,
                :DATA_24 => :string, 
                :DATA_25 => :string, 
                :DATA_26 => :string, 
                :DATA_27 => :string, 
                :DATA_28 => :string,
                :DATA_29 => :string, 
                :DATA_30 => :string,
                :DATA_31 => :string, 
                :DATA_32 => :string, 
                :DATA_33 => :string,
                :DATA_34 => :string, 
                :DATA_35 => :string, 
                :DATA_36 => :string, 
                :DATA_37 => :string, 
                :DATA_38 => :string,
                :DATA_39 => :string,
                :DATA_40 => :string, 
                :DATA_41 => :string, 
                :DATA_42 => :string, 
                :DATA_43 => :string,
                :DATA_44 => :string, 
                :DATA_45 => :string, 
                :DATA_46 => :string, 
                :DATA_47 => :string, 
                :DATA_48 => :string, 
                :DATA_49 => :string,
                :DATA_50 => :string, 
                :PHOTO => :string,
                :SIGNATURE => :string, 
                :MAGTRACK_1 => :string, 
                :MAGTRACK_2 => :string,
                :MAGTRACK_3 => :string, 
                :BARCODE_1 => :string, 
                :BARCODE_2 => :string,
                :BARCODE_3 => :string
              },
              :return => { :return => :string }
  def SetStaffData
    job = PrintJob.find_by(id: params[:token])
    unless job.present?
      Rails.logger.info ("[WSDL:SetStaffData] Response: 02")
      render :soap => { :return => "02" }
      return
    end
  
    begin
      job.add_users(params, true)
      job.save
      return_status = "01"
    rescue Exception => e
      # Keep going
      Rails.logger.error("[WSDL API::SetStaffData] Exception: #{e.to_s}")
      return_status = "02"
    end
    
    Rails.logger.info ("[WSDL:SetStaffData] Response: #{return_status}")
    render :soap => { :return => return_status }
  end

  soap_action "ProduceJob",
              :args   => { :token => :string },
              :return => { :return => :string }
  def ProduceJob
    job = PrintJob.find_by(id: params[:token])
    unless job.present?
      Rails.logger.info ("[WSDL:ProduceJob] Response: 02")
      render :soap => { :return => "02" }
      return
    end
    
    begin
      job.total_cards = job.total_cards_shortcut
      job.special_handlings = job.special_handlings_tokens_shortcut
      job.Scheduled!
      job.charge_organization
      job.save!
      return_status = "01"
    rescue Exception => e
      # Keep going
      Rails.logger.error("[WSDL API::ProduceJob] Exception: #{e.to_s}")
      return_status = "02"
    end
    
    Rails.logger.info ("[WSDL:ProduceJob] Response: #{return_status}")
    render :soap => { :return => return_status }
  end

  soap_action "JobStatus",
              :args   => { :token => :string },
              :return => { :return => :string }
  def JobStatus
    if params[:token].to_i <= 0
      Rails.logger.info ("[WSDL:JobStatus] Response: 02")
      render :soap => { :return => "02" }
      return
    end
    
    job = PrintJob.find_by(id: params[:token])
    if job.present?
      repsonse = "11" if job.Created?
      response = "13" if job.Scheduled? or job.In_Progress?
      response = "14 *#{job.updated_at}" unless response.present?
    else
      # Couldn't find the Job
      reponse = "12"
    end
    
    Rails.logger.info ("[WSDL:JobStatus] Response: #{response}")
    render :soap => { :return => response }
  end

  soap_action "CardInfo",
              :args   => { :email => :string, :CompanyPIN => :string },
              :return => { :return => :string }
  def CardInfo
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:CardInfo] Response: E1#")
      render :soap => { :return => "E1#" }
      return
    end

    card_templates = CardTemplate.where(:organization_id => user.organization_id).where(status_cd: 1)
    shared_templates = SharedTemplate.where(:organization_id => user.organization_id)
    total_shared_templates = shared_templates.count
    extra_response = ""
    shared_templates.each do |ec|
      if ec.clone_card_template_id.present?
        extra_response << "#{ec.clone_card_template_id}~#{ec.card_template.name}#"
      elsif ec.card_template.Approved?
        extra_response << "#{ec.card_template.id}~#{ec.card_template.name}#"
      else
        total_shared_templates -= 1
      end
    end
    
    total_cards = card_templates.count + total_shared_templates
    if total_cards.eql? 0
      Rails.logger.info ("[WSDL:CardInfo] Response: E2#")
      render :soap => { :return => "E2#" }
      return
    end
    
    response = ""
    card_templates.each do |ct|
      response << "#{ct.id}~#{ct.name}#"
    end

    response = "#{total_cards}#" + response + extra_response

    # Rails.logger.info ("[WSDL:CardInfo] Response: #{response}")
    render :soap => { :return => response }
  end

  soap_action "CardFields",
              :args   => { :email => :string, :CompanyPIN => :string, :CardRefNum => :integer },
              :return => { :return => :string }
  def CardFields
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:CardFields] Response: E2#")
      render :soap => { :return => "E2#" }
      return
    end
    
    card = user_card_template_validation(user)
    unless card.present?
      Rails.logger.info ("[WSDL:CardFields] Response: E1#")
      render :soap => { :return => "E1#" }
      return
    end
    
    response = ""
    total_fields = 0
    card.template_fields.each do |tf|
      case tf["type"]
      when "text", "barcode", "qrcode", "track1", "track2", "track3"
        response << "#{CardTemplate.template_fields_label(tf)}~0~#"
        total_fields += 1
      when "placeholder"
        response << "~0~#"
        total_fields += 1
      when "selectbox"
        response << "#{CardTemplate.template_fields_label(tf)}~1~#{tf['options'].join("^")}^#"
        total_fields += 1
      when "calculated_date"
        response << "#{CardTemplate.template_fields_label(tf)}~5~#"
        total_fields += 1
      when "checkbox"
        response << "#{CardTemplate.template_fields_label(tf)}~6~#{tf['checked']}^#{tf['unchecked']}^#"
        total_fields += 1
      when "date"
        response << "#{CardTemplate.template_fields_label(tf)}~7~#"
        total_fields += 1
      when "radiobox"
        # This field is not yet supported by the PHP front end
        response << "#{CardTemplate.template_fields_label(tf)}~8~#{tf['options'].join("^")}^#"
        total_fields += 1
      end
    end
    
    # Rails.logger.info ("[WSDL:CardFields] Response: #{response}")
    render :soap => { :return => "#{total_fields}##{response}"}
  end

  soap_action "ImageSizes",
              :args   => { :email => :string, :CompanyPIN => :string, :CardRefNum => :integer },
              :return => { :return => :string }
  def ImageSizes
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:ImageSizes] Response: E2#")
      render :soap => { :return => "E2#" }
      return
    end

    card = user_card_template_validation(user)
    unless card.present?
      # Card not existent or not associated with same organization as user
      Rails.logger.info ("[WSDL:ImageSizes] Response: E1#")
      render :soap => { :return => "E1#" }
      return
    end
    
    response = ""
    total_images = 0
    card.template_fields.each do |tf|
      case tf["type"]
      when "image"
        response << "#{tf['dimensions']['width']*2*1.4}##{tf['dimensions']['height']*2*1.4}#"
        total_images += 1
      end
    end
    
    if total_images < 2
      response << "0#0#"
    end

    # Rails.logger.info ("[WSDL:ImageSizes] Response: #{response}")
    render :soap => { :return => "#{response}" }
  end

  soap_action "AccBalance",
              :args   => { :email => :string, :CompanyPIN => :string },
              :return => { :return => :string }
  def AccBalance
    # Validate email & pin
    user = user_params
    unless user.present?
      Rails.logger.info ("[WSDL:AccBalance] Response: 02")
      render :soap => { :return => "02" }
      return
    end
    
    unless user.organization.present?
      Rails.logger.info ("[WSDL:AccBalance] Response: 09")
      render :soap => { :return => "09" }
      return
    end

    response = "01##{user.organization.who_pays_for_my_jobs.balance.to_f}##{user.organization.who_pays_for_my_jobs.overdraft.to_f}#"
    # Rails.logger.info ("[WSDL:AccBalance] Response: #{response}")
    render :soap => { :return => response }
  end

  # INFO: This action is NOT described in the Documentation but IT IS available in the current implementation
  # soap_action "WorkingJobNum",
  #             :args   => {},
  #             :return => { :return => :integer }
  # def WorkingJobNum
  #   render :soap => { :return => 5 }
  # end
  
  private
  
  def user_params_with_password
    # TODO (HR): authenticate with Devise
    user = User.includes(:organization).with_role(:admin).where(:email => params[:email].downcase).where(:passwword => params[:password]).first
    (user.present? and user.organization.present?) ? user : nil
  end

  def user_params
    user = User.includes(:organization).with_role(:admin).where(:email => params[:email].downcase).where(:pin => params[:CompanyPIN]).first
    # TODO (HR): possible solution
    # (!user.blank? and !user.organization.blank? and user.organization.system_cd.eql?1) ? user : nil
    (user.present? and user.organization.present? and user.organization.NewSystem?) ? user : nil
  end
  
  def user_card_template_validation(user)
    card_template = CardTemplate.where(:id => params[:CardRefNum]).where(:organization_id => user.organization_id).first
    unless card_template.present?
      shared_templates = SharedTemplate.where(:card_template_id => params[:CardRefNum]).where(:organization_id => user.organization.id)
      card_template = shared_templates.first.card_template if shared_templates.present?
    end
    
    unless card_template.present?
      shared_templates = SharedTemplate.where(:clone_card_template_id => params[:CardRefNum]).where(:organization_id => user.organization.id)
      card_template = shared_templates.first.card_template if shared_templates.present?
    end
    
    card_template
  end
  
end
