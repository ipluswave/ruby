json.extract! card, :id, :organization_id, :card_template_id, :data

json.images card.card_images do |image|
  json.id image.id
  json.url image.print_url
end