
# Create all supported roles
# Master doesn't have an Organization
Role.where(name: "master").first_or_initialize.save
Role.where(name: "operator").first_or_initialize.save

# Organization Admin: have access to the 'online' system
Role.where(name: "admin").first_or_initialize.save
# Staff card owner who can't access the system
Role.where(name: "staff").first_or_initialize.save
# Currently net being used. It is an important role in the CVS system
Role.where(name: "verifier").first_or_initialize.save
# Card owner, can modify only his own information
Role.where(name: "individual").first_or_initialize.save

# To be in sync with PHP UI this has to be created in this order only once
ShippingProvider.where(name: 'USPS').first_or_initialize.save
ShippingProvider.where(name: 'FEDEX Overnight').first_or_initialize.save
ShippingProvider.where(name: 'UPS Overnight').first_or_initialize.save
ShippingProvider.where(name: '').first_or_initialize.save
ShippingProvider.where(name: 'Courier').first_or_initialize.save

# Create Default Card types
# 1. White PVC (default)
# 2. White PVC with magstripe
# 3. White PVC with globe hologram
card_types = ['White PVC', 'White PVC with magstripe', 'White PVC with globe hologram']
card_types.each do |ct|
  c = CardType.where(name: ct).first_or_initialize
  c.description = "#{ct} card"
  c.save
end

font_files = [
  {name: 'Arial', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/arial.ttf']},
  {name: 'Tahoma', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/Tahoma.ttf']},
  {name: 'Lucida Handwriting', global: true, files: ['/studio/fonts/LHANDW.TTF']},
  {name: 'GillSans', global: true, files: ['/studio/fonts/GILSANUB.TTF']},
  {name: 'GillSans Light', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/Gill+Sans+Light.ttf']},
  {name: 'Rockwell', global: true, files: ['/studio/fonts/ROCK.TTF']},
  {name: 'Allerta Stencil', global: false, url: 'http://fonts.googleapis.com/css?family=Allerta+Stencil'},
  {name: 'Garamond', global: true, url: 'http://fonts.googleapis.com/css?family=Garamond'},
  {name: 'EB Garamond', global: false, url: 'http://fonts.googleapis.com/css?family=EB+Garamond'},
  {name: 'Tekton Pro', global: true, files: ["/studio/fonts/TektonPro-Regular.otf"]},
  {name: 'Courier New', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/cour.ttf']},
  {name: 'Verdana', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/verdana.ttf']},
  {name: 'Times New Roman', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/times.ttf']},
  {name: 'Georgia', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/georgia.ttf']},
  {name: 'Impact', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/impact.ttf']},
  {name: 'Cambria', global: true, files: [
    'http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/cambria.ttf',
    'http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/cambriai.ttf',
    'http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/cambriab.ttf',
    'http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/cambriaz.ttf'
    ]},
  {name: 'Comic Sans MS', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/comic.ttf']},
  {name: 'Stencil', global: true, files: ['http://s3-us-west-2.amazonaws.com/dev-instantcard-core/uploads/font/stencil.ttf']}
]

font_files.each do |font| 
  f = Font.where(name: font[:name]).first_or_initialize
  f.files = font[:files] if font[:files].present?
  f.global = font[:global]
  f.url = font[:url] if font[:url].present?
  f.save!
end

industries = ["Internet", "Telecommunications",
  "Healthcare",
  "Police/Fire",
  "EMT",
  "Religious/Faith",
  "School/Education",
  "University/College",
  "Services",
  "Industry",
  "Manufacturing",
  "High Tech",
  "Utilities",
  "Finance",
  "Transportation",
  "Retail/Wholesale",
  "Media/Communications"
]
industries.each do |industry|
  Industry.where(name: industry).first_or_initialize.save
end

categories = ["Normal", "Government", "Non-profit"]
categories.each do |category|
  Category.where(name: category).first_or_initialize.save
end

financial_transaction_sub_types = [
  "Credit by Check",
  "Credit by Credit Card"]

financial_transaction_sub_types.each do |sub_type_name|
  stn = FinancialTransactionSubType.where(name: sub_type_name).first_or_initialize
  stn.description = sub_type_name
  stn.save!
end


card_options = [
  {
      "element" => "options",
      "key" => "color",
      "value" => "colorcolor"
  },
  {
      "element" => "options",
      "key" => "sides",
      "value" => "double"
  },
  {
      "element" => "options",
      "key" => "slot_punch",
      "value" => ""
  }
]

card_options.each do |card_option|
  co = CardOption.where(:element => card_option["element"])
    .where(:key => card_option["key"])
    .where(:value => card_option["value"]).first_or_initialize
  co.save!
end

# Create the types: Credit and Debit
financial_transaction_types = [
  {
    type: 1,
    name: 'Credit'}, 
  {
    type: 2,
    name: 'Debit'}
]

financial_transaction_types.each do |financial_transaction_type|
  new_ftt = FinancialTransactionType.where(transaction_type: financial_transaction_type[:type]).first_or_initialize
  new_ftt.name = financial_transaction_type[:name]
  new_ftt.save!
end

financial_transaction_sub_types = [
  {
    name: "Credit by Check",
    type_name: 'Credit'
  },
  {
    name: "Credit by Credit Card",
    type_name: 'Credit'
  },
  {
    name: "Refund",
    type_name: 'Credit'
  },
  {
    name: "Print Job",
    type_name: 'Debit'
  },
  {
    name: "Other",
    type_name: 'Debit'
  }
]

financial_transaction_sub_types.each do |ftst|
  stn = FinancialTransactionSubType.where(name: ftst[:name]).first_or_initialize
  stn.description = ftst[:name]
  stn.financial_transaction_type = FinancialTransactionType.where(name: ftst[:type_name]).first
  stn.save!
end
