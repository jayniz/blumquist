require 'blumquist/version'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'
require 'json-schema'
require 'blumquist/json_pointer'
require 'blumquist/errors'

class Blumquist
  PRIMITIVE_TYPES = %w{null boolean number string enum integer}.freeze

  attr_reader :_type

  def initialize(options)
    # Poor man's deep clone: json 🆗 🆒
    @data = JSON.parse(options.fetch(:data).to_json)
    @schema = options.fetch(:schema).with_indifferent_access
    @original_properties = options.fetch(:schema).with_indifferent_access[:properties]
    @validate = options.fetch(:validate, true)

    validate_schema
    validate_data

    resolve_json_pointers
    define_getters
  end

  def to_s
    inspect
  end

  def marshal_dump
    [@schema, @data, @validate]
  end

  def marshal_load(array)
    @schema, @data, @validate = array
  end

  def ==(other)
    self.class == other.class && other.marshal_dump == marshal_dump
  end

  alias_method :eql?, :==

  private

  def validate_data
    return unless @validate
    errors = JSON::Validator.fully_validate(@schema, @data)
    return true if errors.length == 0
    raise(Errors::ValidationError, [errors.map { |e| e.split("\n") }, @data])
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

  def resolve_json_pointer(type_def)
    pointer = JSONPointer.new(type_def[:$ref], document: @schema)

    type_def.merge(pointer.value)
  end

  def resolve_json_pointer!(type_def)
    pointer_path = type_def.delete(:$ref)
    pointer = JSONPointer.new(pointer_path, document: @schema)

    type_def.merge!(pointer.value)
  end

  def primitive_type?(type)
    PRIMITIVE_TYPES.include?(type.to_s)
  end

  def define_getters
    @schema[:properties].each do |property, type_def|
      # The type_def can contain one or more types.
      # We only support multiple primitive types, or one
      # normal type and the null type.
      types = [type_def[:type]].flatten - ["null"]
      type = types.first

      # Wrap objects recursively
      if type == 'object' || type_def[:oneOf]
        @data[property] = blumquistify_property(property)

      # Turn array elements into Blumquists
      elsif type == 'array'
        blumquistify_array(property)

      # Nothing to do for primitive values
      elsif primitive_type?(type)

      elsif all_primitive_types(types)

      # We don't know what to do, so let's panic
      else
        raise(Errors::UnsupportedType, type)
      end

      # And define the getter
      define_getter(property)
    end
  end

  def define_getter(property)
    #
    # Inheritance:
    # Define methods under the Blumquist namespace
    # to allow subclasses to overwrite methods.
    #
    Blumquist.class_eval do
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
    sub_blumquist = blumquistify_object(schema: sub_schema, data: data)
    # In case of oneOf the definition was already set
    sub_blumquist._type = type_name_for(property) if sub_blumquist && sub_blumquist._type.nil?
    sub_blumquist
  end

  def blumquistify_object(options)
    sub_schema = options[:schema]
    data = options[:data]

    # If properties are defined directly, like this:
    #
    #     { "type": "object", "properties": { ... } }
    #
    if sub_schema[:properties]
      if sub_schema[:type].is_a?(String)
        sub_blumquist = Blumquist.new(schema: sub_schema, data: data, validate: false)
        return sub_blumquist
      end

      # If the type is an array, we can't make much of it
      # because we wouldn't know which type to model as a
      # blumquist object. Unless, of course, it's one object
      # and one or more primitives.
      if sub_schema[:type].is_a?(Array)

        # It's an array but only contains one allowed type,
        # this is easy.
        if sub_schema[:type].length == 1
          sub_schema[:type] = sub_schema[:type].first
          sub_blumquist = Blumquist.new(schema: sub_schema, data: data, validate: false)
          return sub_blumquist
        end

        # We can implement the other cases at a leter point.
      end

      # We shouldn't arrive here
      raise(Errors::UnsupportedType, sub_schema)
    end

    # Properties not defined directly, object must be 'oneOf',
    # like this:
    #
    #    { "type": "object", "oneOf": [{...}] }
    #
    # The json schema v4 draft specifies, that:
    #
    #    "the oneOf keyword is new in draft v4; its value is an array of
    #    schemas, and an instance is valid if and only if it is valid
    #    against exactly one of these schemas"
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
              schema = resolve_json_pointer(one).merge(
                definitions: @schema[:definitions]
              )
            end
            sub_blumquist = Blumquist.new(data: data, schema: schema, validate: true)
            sub_blumquist._type = type_from_type_def(one)
            return sub_blumquist
          end
        rescue
          # On to the next oneOf
        end
      end

      # We found no matching object definition.
      # If a primitve is part of the `oneOfs,
      # that's no problem though.
      #
      # TODOs this is only ok if data is actually of that primitive type
      #
      # Also check https://gist.github.com/jayniz/e8849ea528af6d205698 and
      # https://github.com/ruby-json-schema/json-schema/issues/319
      return data if primitive_allowed

      # We didn't find a schema in oneOf that matches our data
      raise(Errors::NoCompatibleOneOf, one_ofs: sub_schema[:oneOf], data: data)
    end

    # If there's neither `properties` nor `oneOf`, we don't
    # know what to do and shall panic:
    raise(Errors::MissingProperties, sub_schema)
  end

  def type_from_type_def(type_def)
    return 'object' unless type_def.is_a?(Hash) && type_def.has_key?(:$ref)
    type_def[:$ref].split("/").last
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
      reference_type = type_from_type_def(type_def)
      item_schema = resolve_json_pointer!(type_def)

      sub_schema = item_schema.merge(
        definitions: @schema[:definitions]
      )

      @data[property] ||= []
      @data[property] = @data[property].map do |item|
        sub_blumquist = Blumquist.new(schema: sub_schema, data: item, validate: false)
        sub_blumquist._type = reference_type
        sub_blumquist
      end

    # The items are objects, defined directly or through oneOf
    elsif type_def[:type] == 'object' || type_def[:oneOf]
      sub_schema = type_def.merge(
        definitions: @schema[:definitions]
      )

      @data[property] ||= []
      @data[property] = @data[property].map do |item|
        blumquistify_object(schema: sub_schema, data: item)
      end

    # The items are all of the same primitive type
    elsif primitive_type?(type_def[:type])

    # The items might all be primitives, that would be OK
    elsif all_primitive_types(type_def[:type])

    # We don't know what to do, so let's panic
    else
      raise(Errors::UnsupportedType, type_def[:type])
    end
  end

  def type_name_for(property)
    type_from_type_def(@original_properties[property])
  end

  def all_primitive_types(types)
    return false unless types.is_a?(Array)
    types.all? { |t| primitive_type?(t) }
  end

  protected

  def _type=(_type)
    @_type = _type
  end
end
