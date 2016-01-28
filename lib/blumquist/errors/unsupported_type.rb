class Blumquist
  module Errors
    class UnsupportedType < Blumquist::Error
      def initialize(type)
        super("Unsupported type '#{type.to_s}' (#{%w{null, boolean, number, string, array object}.to_json} are supported)")
      end
    end
  end
end
