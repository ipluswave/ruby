json.array!(@card_templates) do |card_template|
  json.extract! card_template, :id
  json.url card_template_url(card_template, format: :json)
end
