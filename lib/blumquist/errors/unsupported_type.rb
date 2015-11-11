class Blumquist
  module Errors
    class UnsupportedType < RuntimeError
      def initialize(type)
        super("Only null, boolean, number, string, array and object types are supported. Unsupported type #{type.to_s.to_json}")
      end
    end
  end
end
