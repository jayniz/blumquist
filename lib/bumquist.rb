require "bumquist/version"
require 'active_support/core_ext/string'

class Bumquist
  def initialize(schema, data)
    # Poor man's deep clone: json 🆗 🆒
    @data = JSON.parse(data.to_json)
    @schema = schema.with_indifferrent_access
    define_getters
  end

  private 

  def define_getters
  end
end
