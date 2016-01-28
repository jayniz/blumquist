class Blumquist
  module Errors
    class UnsupportedSchema < Blumquist::Error
      def initialize(type)
        super("The top level object of the schema must be \"object\" (it is #{type.to_json})")
      end
    end
  end
end
