class CardTemplatesController < InheritedResources::Base
  before_action :set_card_template, only: [:show, :update, :image, :upload]

  def image
    @user_data_id = params["user_data_id"]
    @side = params["side"]
    @is_preview = params["preview"].present? ? 1 : 0
    render layout: "card_template"
  end
  
  def update
    if params["card_template"]["images"].present?
      @card_template.add_files(params["card_template"]["images"])
    end
    
    redirect_to @card_template, notice: 'Card Template updated successfully.'
  end
  
  private

    def card_template_params
      params.require(:card_template).permit()
    end
    
    def set_card_template
      @card_template = CardTemplate.find(params[:id])
    end
end

