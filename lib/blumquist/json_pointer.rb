#
# JSON Pointer
# This is a VERY BASIC implementation
# to support pointers in the form of:
#
#   1. #/key1/key2/.../keyN
#   2. path_to_file.json
#   3. path_to_file.json#/key1/key2/.../keyN
#
#  More about JSON Pointer & Reference Specification
#  https://cswr.github.io/JsonSchema/spec/definitions_references/#json-pointers
#

class Blumquist
  class JSONPointer
    DOCUMENT_ROOT_IDENTIFIER = '#'.freeze
    DOCUMENT_ADDRESS_IDENTIFIER = '.json'.freeze

    attr_reader :uri

    def initialize(uri, document: nil)
      @uri = uri
      validate_uri!
      @document = document
    end

    def value
      result = keys.any? ? document&.dig(*keys) : document

      raise(Errors::InvalidPointer, pointer: uri, document: document) if result.nil?

      result
    end

    private

    def keys
      return @keys if defined?(@keys)

      @keys = @uri.split('#')[1]
      @keys = @keys&.sub('/', '') if @keys&.start_with?('/')
      @keys = @keys&.split('/') || []
    end

    def address
      return @address if defined?(@address)

      @address = uri.scan(/.*\.json/).first
    end

    def document
      if points_to_document_address?
        @external_document ||= JSON.parse( File.read(address) )
      else
        @document
      end
    end

    def points_to_document_address?
      !address.nil?
    end

    def validate_uri!
      #
      # Why only this uri formats are valid?
      # Refer to the description on the top of this file
      #

      return if uri.start_with?(DOCUMENT_ROOT_IDENTIFIER)
      return if uri.match(DOCUMENT_ADDRESS_IDENTIFIER)

      raise(Errors::UnsupportedPointer, pointer: uri)
    end
  end
end
