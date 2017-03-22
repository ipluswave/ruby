class OrganizationsController < InheritedResources::Base

  private

    def organization_params
      params.require(:organization).permit()
    end
end

