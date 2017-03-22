json.array!(@costs) do |cost|
  json.extract! cost, :id
  json.url cost_url(cost, format: :json)
end
