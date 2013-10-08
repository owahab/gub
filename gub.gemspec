# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gub/version'

Gem::Specification.new do |spec|
  spec.name          = "gub"
  spec.version       = Gub::VERSION
  spec.authors       = ["Omar Abdel-Wahab"]
  spec.email         = ["owahab@gmail.com"]
  spec.description   = %q{The missing command line tool for Github}
  spec.summary       = %q{The missing command line tool for Github}
  spec.homepage      = "http://github.com/owahab/gub"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'debugger'
  
  spec.add_dependency 'thor'
  spec.add_dependency 'octokit'
  spec.add_dependency 'terminal-table'
  spec.add_dependency 'highline'
  spec.add_dependency 'launchy'
end
