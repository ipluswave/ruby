class CardsController < InheritedResources::Base

  def preview
    @card = Card.find(params["card_id"])
    @side = params["side"]
    
    render layout: "card_template"
  end

end