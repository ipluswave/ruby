require 'savon'
require 'pry'

client = Savon::Client.new(wsdl: "http://localhost:3000/icard/wsdl")

begin
=begin
string email, string CompanyPIN, int CardRefNum,
int NumOfCards, string Title, string FirstName, string LastName,
string FullName, string Add1, string Add2, string Add3, string Add4,
string Postcode, string PaymentRef, int PrintInvoice, int NumOfItems,
int Num1, string Des1, double Cost1, int Num2, string Des2, double Cost2,
int Num3, string Des3, double Cost3, int Num4, string Des4, double Cost4,
int Num5, string Des5, double Cost5, int Num6, string Des6, double Cost6,
int Num7, string Des7, double Cost7, int Num8, string Des8, double Cost8,
int Num9, string Des9, double Cost9, int Num10, string Des10, double Cost10,
int PrintLetter, string LetterText, int ShipMethod
=end

  params = {:email => "yannfink@gmail.com", "CompanyPIN" => "1234", "CardRefNum" => 10321, "NumOfCards" => 1,
    "Title" => 'Title', "FirstName" => 'Fist Name', "LastName" => 'Last Name',
    "FullName" => 'Full Name', "Add1" => 'Add 1', "Add2" => 'Add 2', "Add3" => 'Add 3', "Add4" => 'Add 4',
    "Postcode" => 'Post code', 'PaymentRef' => 'Payment Ref', 'PrintInvoice' => 1, "NumOfItems" => 2
  }
  
  result = client.call(:set_job_address, message: params)
  puts result.to_hash.to_s

  result = client.call(:set_job_address_ship, message: params.merge({ "ShipMethod" => 1}))
  puts result.to_hash.to_s

  result = client.call(:set_job_address_ship, message: params.merge({ "ShipMethod" => 2}))
  puts result.to_hash.to_s

rescue Exception => e
  puts "Exception: #{e.to_s}"
end
