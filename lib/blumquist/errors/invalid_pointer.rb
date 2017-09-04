class Blumquist
  module Errors
    class InvalidPointer < Blumquist::Error
      def initialize(pointer:, document:)
          msg = %{
  Could not find pointer '#{pointer}' in the given document:\n
  #{JSON.pretty_generate(document)}
          }

          super(msg)
      end
    end
  end
end
