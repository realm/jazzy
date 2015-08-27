require 'date'
require 'pathname'
require 'mustache'

require 'jazzy/config'
require 'jazzy/gem_version'
require 'jazzy/jazzy_markdown'

module Jazzy
  class Doc < Mustache
    self.template_name = 'doc'

    def copyright
      config = Config.instance
      copyright = config.copyright || (
        # Fake date is used to keep integration tests consistent
        date = ENV['JAZZY_FAKE_DATE'] || DateTime.now.strftime('%Y-%m-%d')
        year = date[0..3]
        "&copy; #{year} [#{config.author_name}](#{config.author_url}). " \
        "All rights reserved. (Last updated: #{date})"
      )
      Jazzy.copyright_markdown.render(copyright).chomp
    end

    def jazzy_version
      # Fake version is used to keep integration tests consistent
      ENV['JAZZY_FAKE_VERSION'] || Jazzy::VERSION
    end
  end
end
