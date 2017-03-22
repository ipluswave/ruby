json.array! @card_types do |ct|
  json.id ct.id
  json.name ct.name
  json.description ct.description
  json.width ct.width
  json.height ct.height
end
