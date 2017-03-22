require 'savon'
require 'pry'

client = Savon::Client.new(wsdl: "http://localhost:3000/icard/wsdl")
# client = Savon::Client.new(wsdl: "https://instantcard.herokuapp.com/icard/wsdl")
# client = Savon::Client.new(wsdl: "http://core.instantcard.net/icard/wsdl")
# client = Savon::Client.new(wsdl: "http://instantcardprod.net/webcardserver.dll/wsdl/ICardInterface")

ops = client.operations 
# IC instance returning:
# [:log_in, :set_job, :set_job_ship, :set_job_address, :set_job_address_ship, :preview_card, :set_staff_data, :produce_job, :job_status, :card_info, :card_fields, :image_sizes]
# Prod instance returning:
# => [:log_in, :working_job_num, :set_job, :set_job_ship, :card_info, :card_fields, :image_sizes, :set_job_address, :set_job_address_ship, :set_staff_data, :preview_card, :produce_job, :job_status]
puts ops.to_s

begin
  # result = client.call(:log_in, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234"})
  # result.to_hash
  # IC instance returning:
  # => {:log_in_response=>{:return=>"01"}}
  # Prod instance returning:
  # {:log_in_response=>{:return=>"01", :"@xmlns:ns1"=>"urn:CardInterfaceIntf-ICardInterface"}, :"@soap_env:encoding_style"=>"http://schemas.xmlsoap.org/soap/encoding/"}

  result = client.call(:set_job, message: { :email => "TEST@ID.COM", "CardRefNum" => 1234, "NumOfCards" => 1 })
  puts result.to_hash.to_s
  
  result = client.call(:set_job_ship, message: { :email => "TEST@ID.COM", "CardRefNum" => 1234, "NumOfCards" => 1, "ShipMethod" => 1 })
  puts result.to_hash.to_s
  
  # result = client.call(:image_sizes, message: { :email => "test@test.com", "CardRefNum" => 1234, "CardRefNum" => 10000 })
  # puts result.to_hash.to_s

  result = client.call(:card_info, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234", "CardRefNum" => 1234})
  puts result.to_hash.to_s
  
  result = client.call(:card_fields, message: { :email => "TEST@ID.COM", "CompanyPIN" => "1234", "CardRefNum" => 1234})
  puts result.to_hash.to_s
  
rescue Exception => e
  puts "Exception: #{e.to_s}"
end
