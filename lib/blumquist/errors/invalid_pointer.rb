class Blumquist
  module Errors
    class InvalidPointer < Blumquist::Error
      def initialize(pointer)
        super("Could not find pointer #{pointer.to_s.to_json}")
      end
    end
  end
end
