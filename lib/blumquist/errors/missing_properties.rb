class Blumquist
  module Errors
    class MissingProperties < Blumquist::Error
      def initialize(type)
        super("Neither 'properties' nor 'oneOf' defined in #{type.to_s.to_json}")
      end
    end
  end
end
