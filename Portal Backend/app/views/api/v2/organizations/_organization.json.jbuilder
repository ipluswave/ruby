json.extract! @organization, :id
json.total_cards @organization.total_cards
json.total_templates @organization.total_card_templates
if @organization.hide_balance?
  @organization.settings.merge!({hide_balance: true})
else
  @organization.settings.delete("hide_balance")
end
json.extract! @organization, :settings