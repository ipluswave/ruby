class Reports::Data::VsPlans < Reports::Data::Base
  def initialize dealer, options={}
    @records = ::VendorService::Plan.joins(:dealer_account).where(dealer: dealer, vendor_panel_dealer_accounts: { active: true })
  end

  def group model_name
    case model_name
    when 'dealer_account'
      @records = @records.group(:dealer_account_id)
    when 'area'
      @records = @records.group(:area_id)
    when 'service_zone'
      @records = @records.group(:service_zone_id)
    when 'location'
      @records = @records.group(:location_id)
    when 'holding'
      @records = @records.group('"vendor_panel_dealer_accounts"."holding_id"')
    when 'master'
      raise Reports::Exception, "Невозможно вывести планы закупок по мастерам"
    else
      super model_name
    end
  end
end
