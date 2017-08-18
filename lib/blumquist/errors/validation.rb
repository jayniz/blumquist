class Blumquist
  module Errors
    class ValidationError < Blumquist::Error
      def initialize(errors)
        super(JSON.pretty_generate(JSON.parse(errors.to_json)))
      end
    end
  end
end
