json.extract! card_template, :id, :name, :organization_id, :card_type_id, :front_data, :back_data, :options

json.images card_template.images do |image|
	json.id image.id
	json.url image.print_url
end

json.extract! card_template, :template_fields, :card_data
json.special_handlings card_template.special_handlings do |sh|
	json.id sh.id
	json.name sh.name
end
