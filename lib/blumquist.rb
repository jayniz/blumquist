require "blumquist/version"
require 'active_support/core_ext/hash/indifferent_access'
require 'json'
require 'json-schema'
require 'blumquist/errors'

class Blumquist
  def initialize(options)
    # Poor man's deep clone: json 🆗 🆒
    @data = JSON.parse(options.fetch(:data).to_json)
    @schema = options.fetch(:schema).with_indifferent_access
    @validate = options.fetch(:validate, true)

    validate_schema
    validate_data

    resolve_json_pointers
    define_getters
  end

  private

  def validate_data
    return unless @validate
    JSON::Validator.validate!(@schema, @data)
  end

  def validate_schema
    return if @schema[:type] == 'object'
    raise(Errors::UnsupportedType, @schema[:type])
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

    raise(Errors::InvalidPointer, pointer) unless definition

    type_def.merge! definition
  end

  def primitive_type?(type)
    %w{null boolean number string}.include? type.to_s
  end

  def define_getters
    @schema[:properties].each do |property, type_def|
      types = [type_def[:type]].flatten - ["null"]
      type = types.first

      # The type_def can contain one or more types.
      # We only support single types, or one
      # normal type and the null type.
      raise(Errors::UnsupportedType, type_def[:type]) unless types.length == 1

      # Wrap objects recursively
      if type == 'object'
        blumquistify_object(property)

      # Turn array elements into Blumquists
      elsif type == 'array'
        blumquistify_array(property)

      # Nothing to do for primitive values
      elsif primitive_type?(type)

      # We don't know what to do, so let's panic
      else
        raise(Errors::UnsupportedType, type)
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
    @data[property] = Blumquist.new(schema: sub_schema, data: @data[property], validate: @validate)
  end

  def blumquistify_array(property)
    # We only support arrays with one type defined, either through
    #
    #     "type": "array",
    #     "items": { "$ref": "#/definitions/mytype" }
    #
    # or through
    #
    #     "type": "array",
    #     "items": [{ "$ref": "#/definitions/mytype" }]
    #
    # or through
    #
    #     "type": "array",
    #     "items": [{ "type": "number" }]
    #
    type_def = [@schema[:properties][property][:items]].flatten.first

    # The items of this array are defined by a pointer
    if type_def[:$ref]
      item_schema = resolve_json_pointer!(type_def)
      raise(Errors::MissingArrayItemsType, @schema[:properties][property]) unless item_schema

      sub_schema = item_schema.merge(
        definitions: @schema[:definitions]
      )

      @data[property] ||= []
      @data[property] = @data[property].map do |item|
        Blumquist.new(schema: sub_schema, data: item, validate: @validate)
      end
    elsif primitive_type?(type_def[:type])

    # We don't know what to do, so let's panic
    else
      raise(Errors::UnsupportedType, type_def[:type])
    end
  end
end
