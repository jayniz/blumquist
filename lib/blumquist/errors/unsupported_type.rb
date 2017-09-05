class Blumquist
  module Errors
    class UnsupportedType < Blumquist::Error
      def initialize(type)
        super("Unsupported type '#{type.to_s}' (#{Blumquist::PRIMITIVE_TYPES.to_json}) are supported)")
      end
    end
  end
end
