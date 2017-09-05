class Blumquist
  module Errors
    class UnsupportedPointer < Blumquist::Error
      def initialize(pointer:)
        msg = %{
  Pointer '#{pointer}' is not supported. Current supported formats are:\n
    1. #/key1/key2/.../keyN
    2. path_to_file.json
    3. path_to_file.json#/key1/key2/.../keyN
        }

        super(msg)
      end
    end
  end
end
