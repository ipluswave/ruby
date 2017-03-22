class Api::V2::DocsController < Api::V2::ApplicationController
  layout false
  
  def api
  end
  
  def show
    @id = params[:id]
    respond_to do |format|
      format.html { render :partial => "api/v2/docs/#@id.json" }
      format.json { render :partial => "api/v2/docs/#@id.json" }
    end
  end
end
