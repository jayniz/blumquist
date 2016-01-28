# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blumquist/version'

Gem::Specification.new do |spec|
  spec.name          = "blumquist"
  spec.version       = Blumquist::VERSION
  spec.authors       = ["Jannis Hermanns"]
  spec.email         = ["jannis@moviepilot.com"]

  spec.summary       = "Turn some data and a json schema into an immutable object with getters from the schema"
  spec.description   = "What the summary said."
  spec.homepage      = "https://github.com/moviepilot/blumquist"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "json-schema"

  spec.add_development_dependency "bundler", "~> 1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-ctags-bundler"
end
