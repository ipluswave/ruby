Swagger::Docs::Config.register_apis({
  "1.0" => {
    :controller_base_path => "/api/v1",
    # the extension used for the API
    # :api_extension_type => :json,
    # the output location where your .json files are written to
    :api_file_path => "app/views/api/v1/docs",
    # the URL base path to your API
    :base_path => "api/v1/docs/",
    :base_api_controller => "Api::V1::BaseController",
    # if you want to delete all .json files at each generation
    :clean_directory => false,
    # add custom attributes to api-docs
    :attributes => {
      :info => {
        "title" => "Swagger InstantCard",
        "description" => "InstantCard JSON/REST API version 1.0.",
        # "termsOfServiceUrl" => "http://helloreverb.com/terms/",
        # "contact" => "apiteam@wordnik.com",
        # "license" => "Apache 2.0",
        # "licenseUrl" => "http://www.apache.org/licenses/LICENSE-2.0.html"
      }
    }
  },
  "2.0" => {
    :controller_base_path => "/api/v2",
    # the extension used for the API
    # :api_extension_type => :json,
    # the output location where your .json files are written to
    :api_file_path => "app/views/api/v2/docs",
    # the URL base path to your API
    :base_path => "/api/v2/docs/",
    :base_api_controller => "Api::V2::BaseController",
    # if you want to delete all .json files at each generation
    :clean_directory => false,
    # add custom attributes to api-docs
    :attributes => {
      :info => {
        "title" => "Swagger InstantCard",
        "description" => "InstantCard JSON/REST API version 2.0."
      }
    }
  }
})