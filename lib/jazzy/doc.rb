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
      Markdown.render_copyright(copyright).chomp
    end

    def jazzy_version
      # Fake version is used to keep integration tests consistent
      ENV['JAZZY_FAKE_VERSION'] || Jazzy::VERSION
    end

    def objc_first?
      Config.instance.objc_mode && Config.instance.hide_declarations != 'objc'
    end

    def language
      objc_first? ? 'Objective-C' : 'Swift'
    end

    def language_stub
      objc_first? ? 'objc' : 'swift'
    end
  end
end
