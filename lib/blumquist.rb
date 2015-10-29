require 'pry'
require "blumquist/version"
require 'active_support/core_ext/hash/indifferent_access'
require 'json'

class Blumquist
  def initialize(schema, data)
    # Poor man's deep clone: json 🆗 🆒
    @data = JSON.parse(data.to_json)
    @schema = schema.with_indifferent_access

    validate_schema
    resolve_json_pointers
    define_getters
  rescue
    binding.pry
  end

  private 

  def validate_schema
    if @schema[:type] != 'object'
      raise "Can only deal with 'object' types, not '#{@schema[:type]}'"
    end
    unless @schema[:properties].is_a?(Hash)
      raise "Properties are a #{@schema[:properties].class.name}, not a Hash"
    end
  end

  def resolve_json_pointers
    @schema[:properties].each do |property, type_def|
      next unless type_def[:$ref]
      resolve_json_pointer!(type_def) 
    end
  end

  def resolve_json_pointer!(type_def)
    # Should read up on how json pointers are really resolved
    pointer = type_def.delete(:$ref)
    key = pointer.split('/').last
    definition = @schema[:definitions][key]

    raise "Can't resolve pointer #{pointer}" unless definition

    type_def.merge! definition
  end

  def primitive_type?(type)
    %w{null boolean number string}.include? type.to_s
  end

  def define_getters
    @schema[:properties].each do |property, type_def|

      # Wrap objects recursively
      if type_def[:type] == 'object'
        blumquistify_object(property)

      # Turn array elements into Blumquists
      elsif type_def[:type] == 'array'
        blumquistify_array(property)

      # Nothing to do for primitive values
      elsif primitive_type?(type_def[:type])

      # We don't know what to do, so let's panic
      else
        raise "Can't handle type '#{type_def}' yet, I'm sorry"
      end

      # And define the getter
      define_getter(property)
    end
  end

  def define_getter(property)
    self.class.class_eval do 
      define_method(property) do
        @data[property]
      end
    end
  end

  def blumquistify_object(property)
    sub_schema = @schema[:properties][property].merge(
      definitions: @schema[:definitions]
    )
    @data[property] = Blumquist.new(sub_schema, @data[property])
  end

  def blumquistify_array(property)
    item_schema = resolve_json_pointer!(@schema[:properties][property][:items])
    sub_schema = item_schema.merge(
      definitions: @schema[:definitions]
    )
    @data[property] ||= []
    @data[property] = @data[property].map do |item|
      Blumquist.new(sub_schema, item)
    end
  end
end
