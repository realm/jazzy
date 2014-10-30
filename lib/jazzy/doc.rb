module Jazzy
  class Doc < Mustache
    self.template_path = File.dirname(__FILE__) + '/..'

    def date
      # Fake date is used to keep integration tests consistent
      ENV['JAZZY_FAKE_DATE'] || DateTime.now.strftime('%Y-%m-%d')
    end

    def year
      # Fake date is used to keep integration tests consistent
      ENV['JAZZY_FAKE_DATE'][0..3] || DateTime.now.strftime('%Y')
    end

    def jazzy_version
      Jazzy::VERSION
    end
  end
end
