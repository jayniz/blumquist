class Blumquist
  module Errors
    class ValidationError < Blumquist::Error
      def initialize(errors)
        super(errors.to_json)
      end
    end
  end
end
