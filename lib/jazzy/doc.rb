require 'date'
require 'pathname'
require 'mustache'

require 'jazzy/gem_version'

module Jazzy
  class Doc < Mustache
    self.template_name = 'doc'

    def jazzy_version
      # Fake version is used to keep integration tests consistent
      ENV['JAZZY_FAKE_VERSION'] || Jazzy::VERSION
    end
  end
end
