class Blumquist
  module Errors
    class ValidationError < Blumquist::Error
      def initialize(json_schema_gem_exception, schema, data)
        super("#{json_schema_gem_exception} for #{data.to_json}")
      end
    end
  end
end
