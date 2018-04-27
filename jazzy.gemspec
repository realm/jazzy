# coding: utf-8

require File.expand_path('lib/jazzy/gem_version.rb', File.dirname(__FILE__))

Gem::Specification.new do |spec|
  spec.name          = 'jazzy'
  spec.version       = Jazzy::VERSION
  spec.authors       = ['JP Simard', 'Tim Anglade', 'Samuel Giddins']
  spec.email         = ['jp@realm.io']
  spec.summary       = 'Soulful docs for Swift & Objective-C.'
  spec.description   = 'Soulful docs for Swift & Objective-C. ' \
                       "Run in your Xcode project's root directory for " \
                       'instant HTML docs.'
  spec.homepage      = 'https://github.com/realm/jazzy'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   << 'jazzy'

  spec.add_runtime_dependency 'cocoapods', '~> 1.0'
  spec.add_runtime_dependency 'mustache', '~> 0.99'
  spec.add_runtime_dependency 'open4'
  spec.add_runtime_dependency 'redcarpet', '~> 3.2'
  spec.add_runtime_dependency 'rouge', ['>= 2.0.6', '< 4.0']
  spec.add_runtime_dependency 'sass', '~> 3.4'
  spec.add_runtime_dependency 'sqlite3', '~> 1.3'
  spec.add_runtime_dependency 'xcinvoke', '~> 0.3.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.3'

  spec.required_ruby_version = '>= 2.0.0'
end
