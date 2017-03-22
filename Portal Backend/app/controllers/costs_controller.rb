class CostsController < InheritedResources::Base

  private

    def cost_params
      params.require(:cost).permit()
    end
end

