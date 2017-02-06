require 'action_view'
class Reports::Builder
  include ActionView::Helpers::NumberHelper
  attr_reader :filter

  def initialize dealer, filter=nil
    @dealer = dealer
    @filter = filter.to_hash
  end

  def result
    filter["where"] ||= {}
    active_record = active_record_model(filter['model'])
    conditions = filter["where"] || {}
    active_record.where(conditions)
    ids = active_record.ids
    @result = Array.new(ids.length) { Array.new(filter['requests'].length) { 0 }}
    filter['requests'].each_with_index do |request, column|
      request_data = {}
      active_record = active_record_model(request['model'] || filter["model"])
      conditions = request["where"] || {}
      conditions.each { |k,v| conditions[k] = range_from(v) if is_range?(v) }
      active_record.where(conditions)
      if request["extra"]
        raise Reports::Exception, "Method \"#{request['extra']}\" not found" unless active_record.respond_to? request['extra']
        active_record.send(request['extra'])
      end
      active_record.group(filter["model"])
      if request['aggregate']
        request['field'] ||= 'id'
        request_data = active_record.send(request['aggregate'], *request['field'])
      else
        request_data = active_record.send(request['field'])
      end
      ids.each_with_index do |id, row|
        @result[row][column] = process(request_data[id])
      end
    end
    @result
  end

  private

  def process value
    if (value.is_a? BigDecimal)
      return value.to_f
    else
      return value
    end
  end

  def active_record_model model_name
    "Reports::Data::#{model_name.camelize}".constantize.new(@dealer)
  end

  def is_range? value
    value.is_a?(Hash) && value.has_key?('startDate') && value.has_key?('endDate')
  end

  def range_from value
    value['startDate'].to_datetime..value['endDate'].to_datetime.end_of_day
  end
end

# Example Filter
# {
#   "model" => "dealer_account",
#   "requests" => [
#     {
#       "model" => "vs_order",
#       "field" => "total_cost",
#       "aggregate" => "maximum",
#       "where" => {
#         "closed_at" => {
#           "startDate" => "01.01.2016",
#           "endDate" => "01.03.2016"
#         }
#       }
#     },
#     {
#       "model" => "vs_order",
#       "field" => "total_cost",
#       "aggregate" => "count",
#       "where" => {
#         "closed_at" => {
#           "startDate" => "01.01.2016",
#           "endDate" => "01.03.2016"
#         }
#       }
#     },
#     {
#       "field" => "zone_title",
#     }
#   ]
# }
