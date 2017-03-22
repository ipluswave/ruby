require 'savon'
require 'pry'

# client = Savon::Client.new(wsdl: "http://localhost:3000/icard/wsdl")
client = Savon::Client.new(wsdl: "http://instantcardprod.net/webcardserver.dll/wsdl/ICardInterface")

# IC instance returning:
# [:log_in, :set_job, :set_job_ship, :set_job_address, :set_job_address_ship, :preview_card, :set_staff_data, :produce_job, :job_status, :card_info, :card_fields, :image_sizes]

begin
  result = client.call(:log_in, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234"})
  puts result.to_hash

  result = client.call(:card_info, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234"})
  puts result.to_hash
  # "3#579~AAIDP Multi-field#3867~AAIDP Volunteer#3856~AAIDP photo+signature#"
  
  result_579 = client.call(:card_fields, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234", "CardRefNum" => 579})
  puts result_579.to_hash
  
  result_3867 = client.call(:card_fields, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234", "CardRefNum" => 3867})
  puts result_3867.to_hash
  
  result_3856 = client.call(:card_fields, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234", "CardRefNum" => 3856})
  puts result_3856.to_hash
  
rescue Exception => e
end