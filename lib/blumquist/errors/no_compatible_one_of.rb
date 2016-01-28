class Blumquist
  module Errors
    class NoCompatibleOneOf < Blumquist::Error
      def initialize(options)
        data = options[:data]
        one_ofs = options[:one_ofs]
        super("Could not find a matching schema for #{data.to_json} in the oneOfs: #{one_ofs.to_json}")
      end
    end
  end
end
