# coding: utf-8
# frozen_string_literal: true

require File.expand_path('lib/jazzy/gem_version.rb', File.dirname(__FILE__))

Gem::Specification.new do |spec|
  spec.name          = 'jazzy'
  spec.version       = Jazzy::VERSION
  spec.authors       = ['JP Simard', 'Tim Anglade', 'Samuel Giddins', 'John Fairhurst']
  spec.email         = ['jp@jpsim.com']
  spec.summary       = 'Soulful docs for Swift & Objective-C.'
  spec.description   = 'Soulful docs for Swift & Objective-C. ' \
    "Run in your SPM or Xcode project's root directory for " \
    'instant HTML docs.'
  spec.homepage      = 'https://github.com/realm/jazzy'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables << 'jazzy'

  spec.add_runtime_dependency 'cocoapods', '~> 1.5'
  spec.add_runtime_dependency 'mustache', '~> 1.1'
  spec.add_runtime_dependency 'open4', '~> 1.3'
  spec.add_runtime_dependency 'redcarpet', '~> 3.4'
  spec.add_runtime_dependency 'rexml', '~> 3.2'
  spec.add_runtime_dependency 'rouge', ['>= 2.0.6', '< 5.0']
  spec.add_runtime_dependency 'sassc', '~> 2.1'
  spec.add_runtime_dependency 'sqlite3', '~> 1.3'
  spec.add_runtime_dependency 'xcinvoke', '~> 0.3.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'

  spec.required_ruby_version = '>= 2.6.3'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
