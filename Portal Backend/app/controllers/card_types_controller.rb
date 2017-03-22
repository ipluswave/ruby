class CardTypesController < InheritedResources::Base

  private

    def card_type_params
      params.require(:card_type).permit()
    end
end

