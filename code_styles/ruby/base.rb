class Reports::Data::Base
  attr_reader :records
  delegate :count, :average, :maximum, :minimum, :sum, :map, :pluck, to: :records

  def initialize dealer, options={}
    @records = nil
    @options = options
  end

  def ids
    @records.pluck(:id)
  end

  def where conditions
    @records = @records.where(conditions)
  end

  def group model_name
    raise Reports::Exception, "Unknow group by '#{model_name}' in #{self.class.name}" unless self.class.name.eql? "Reports::Data::#{model_name.camelize}"
  end

  def method_missing(method_sym, *arguments, &block)
    attribute_name = method_sym.to_s
    if @records.attribute_names.include? attribute_name
      @records.map{ |x| [x.id, x[attribute_name]]}.to_h
    else
      @records.map{ |x| [x.id, nil]}.to_h
    end
  end
end
