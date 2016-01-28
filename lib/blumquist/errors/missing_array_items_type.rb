class Blumquist
  module Errors
    class MissingArrayItemstype < Blumquist::Error
      def initialize(property)
        super("Array items' type missing in #{property.to_json}")
      end
    end
  end
end
