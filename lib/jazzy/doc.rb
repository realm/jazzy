require 'date'

require 'jazzy/gem_version'

module Jazzy
  class Doc < Mustache
    self.template_path = File.dirname(__FILE__) + '/..'

    def date
      # Fake date is used to keep integration tests consistent
      ENV['JAZZY_FAKE_DATE'] || DateTime.now.strftime('%Y-%m-%d')
    end

    def year
      # Fake date is used to keep integration tests consistent
      if ENV['JAZZY_FAKE_DATE']
        ENV['JAZZY_FAKE_DATE'][0..3]
      else
        DateTime.now.strftime('%Y')
      end
    end

    def jazzy_version
      # Fake version is used to keep integration tests consistent
      ENV['JAZZY_FAKE_VERSION'] || Jazzy::VERSION
    end
  end
end
