require 'barby'
require 'barby/barcode'
require 'barby/barcode/qr_code'
require 'barby/outputter/png_outputter'

str = 'http://instantcard.net/online/'

# b = Barby::QrCode.new(str, level: :q, size: 40)
# b = Barby::QrCode.new(str, level: :l)
b = RQRCode::QRCode.new(str, level: :l)
File.open('qr_rqr.png', 'w') do |f|
  f.write b.as_png(module_px_size: 20)
  f.close
end

b = Barby::QrCode.new(str, level: :l)
File.open('qr_brb.png', 'w') do |f|
  f.write b.to_png(module_px_size: 20)
  f.close
end

