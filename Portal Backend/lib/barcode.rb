require 'barby/barcode/code_128'
require 'barby/barcode/code_39'
require 'barby/barcode/code_25'
require 'barby/barcode/code_25_interleaved'
require 'barby/barcode/code_25_iata'
require 'barby/outputter/png_outputter'
require 'pry'

barcode_data = '112'
symbology = 'code39'
barcode = nil

begin
  case symbology
  when "code128A"
    barcode = Barby::Code128A.new(barcode_data)
  when "code128B"
    barcode = Barby::Code128B.new(barcode_data)
  when "code128C"
    barcode = Barby::Code128C.new(barcode_data)
  when "code39"
    barcode = Barby::Code39.new(barcode_data, {height: 112})
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

blob = Barby::PngOutputter.new(barcode).to_png({height: 112}) #Raw PNG data
File.open('barcode.png', 'wb'){|f| f.write blob }
