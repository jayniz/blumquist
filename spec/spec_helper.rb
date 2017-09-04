$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])
SimpleCov.start{ add_filter 'spec/'}

require 'blumquist'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.order = :random
end
