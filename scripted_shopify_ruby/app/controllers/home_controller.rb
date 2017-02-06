class HomeController < AuthenticatedController
  def index
    @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
  end

  def authenticate
    require 'net/http'
    require 'json'

    key = params[:api_key]
    token = params[:api_token]

    uri = URI.parse("https://api.scripted.com/#{key}/v1/industries")
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{token}"
      response = http.request request
      # puts '----response----------'
      # puts response
      # parsed = JSON.parse(response.body)
      #parsed = JSON.parse([response.body].to_json)

      ScriptedClient.organization_key = key
      ScriptedClient.access_token = token
      # ScriptedClient.env = :sandbox
      # ScriptedClient::JobTemplate.all

      redirect_to jobs_url
    end

    # if(parsed==true)
    #
    # end
    #
    # else
    # {
    #   "errors": [
    #       "Topic is too long (maximum is 255 characters)",
    #       "Quantity must be one of the ContentFormat's quantity_options"
    #   ]
    # }
  end
end
