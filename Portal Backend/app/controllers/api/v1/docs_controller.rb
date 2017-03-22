class Api::V1::DocsController < Api::V1::BaseController
  layout false
  
  def api
  end
  
  def show
    @id = params[:id]
    respond_to do |format|
      format.html { render :partial => "api/v1/docs/#@id.json" }
      format.json { render :partial => "api/v1/docs/#@id.json" }
    end
  end
end
