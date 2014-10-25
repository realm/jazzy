# coding: utf-8

require File.expand_path('lib/jazzy/gem_version.rb', File.dirname(__FILE__))

Gem::Specification.new do |spec|
  spec.name          = "jazzy"
  spec.version       = Jazzy::VERSION
  spec.authors       = ["JP Simard, Tim Anglade"]
  spec.email         = ["jp@realm.io"]
  spec.summary       = %q{A soulful way to generate docs for Swift.}
  spec.description   = %q{A soulful way to generate docs for Swift. Run in your Xcode project's root directory for instant HTML docs.}
  spec.homepage      = "http://github.com/realm/jazzy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   << 'jazzy'

  spec.add_runtime_dependency 'mustache', '~> 0.99.5'
  spec.add_runtime_dependency 'activesupport', '~> 4.1.1'
  spec.add_runtime_dependency 'redcarpet', '~> 3.1.2'
  spec.add_runtime_dependency 'nokogiri', '~> 1.6.2.1'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
