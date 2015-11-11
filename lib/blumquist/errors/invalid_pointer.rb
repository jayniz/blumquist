class Blumquist
  module Errors
    class InvalidPointer < RuntimeError
      def initialize(pointer)
        super("Could not find pointer #{pointer.to_s.to_json}")
      end
    end
  end
end
