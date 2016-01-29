require 'blumquist/version'
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
    raise(Errors::UnsupportedSchema, type: @schema[:type])
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
      raise(Errors::UnsupportedType, type_def[:type]) if types.length > 1

      # Wrap objects recursively
      if type == 'object' || type_def[:oneOf]
        @data[property] = blumquistify_property(property)

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

  def blumquistify_property(property)
    sub_schema = @schema[:properties][property].merge(
      definitions: @schema[:definitions]
    )
    data = @data[property]
    blumquistify_object(schema: sub_schema, data: data)
  end

  def blumquistify_object(options)
    sub_schema = options[:schema]
    data = options[:data]

    # If properties are defined directly, like this:
    #
    #     { "type": "object", "properties": { ... } }
    #
    if sub_schema[:properties]
      sub_blumquist = Blumquist.new(schema: sub_schema, data: data, validate: @validate)
      return sub_blumquist
    end

    # Properties not defined directly, object must be 'oneOf',
    # like this:
    #
    #    { "type": "object", "oneOf": [{...}] }
    #
    # The json schema v4 draft specifies, that:
    #
    #    "the oneOf keyword is new in draft v4; its value is an array of schemas, and an instance is valid if and only if it is valid against exactly one of these schemas"
    #
    # *See: http://json-schema.org/example2.html
    #
    # That means we can just go through the oneOfs and return
    # the first that matches:
    if sub_schema[:oneOf]
      primitive_allowed = false
      sub_schema[:oneOf].each do |one|
        begin
          if primitive_type?(one[:type])
            primitive_allowed = true
          else
            if one[:type]
              schema = one.merge(definitions: @schema[:definitions])
            else
              schema = resolve_json_pointer!(one).merge(
                definitions: @schema[:definitions]
              )
            end
            return Blumquist.new(data: data, schema: schema)
          end
        rescue
          # On to the next oneOf
        end
      end

      # We found no matching object definition.
      # If a primitve is part of the `oneOfs,
      # that's no problem though.
      return if primitive_allowed

      # We didn't find a schema in oneOf that matches our data
      raise(Errors::NoCompatibleOneOf, one_ofs: sub_schema[:oneOf], data: data)
    end

    # If there's neither `properties` nor `oneOf`, we don't
    # know what to do and shall panic:
    raise(Errors::MissingProperties, sub_schema)
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

      sub_schema = item_schema.merge(
        definitions: @schema[:definitions]
      )

      @data[property] ||= []
      @data[property] = @data[property].map do |item|
        Blumquist.new(schema: sub_schema, data: item, validate: @validate)
      end
    elsif type_def[:type] == 'object' || type_def[:oneOf]
      sub_schema = type_def.merge(
        definitions: @schema[:definitions]
      )

      @data[property] ||= []
      @data[property] = @data[property].map do |item|
        blumquistify_object(schema: sub_schema, data: item)
      end

    elsif primitive_type?(type_def[:type])

    # We don't know what to do, so let's panic
    else
      raise(Errors::UnsupportedType, type_def[:type])
    end
  end
end
