require 'date'
require 'pathname'
require 'mustache'

require 'jazzy/config'
require 'jazzy/gem_version'
require 'jazzy/jazzy_markdown'

module Jazzy
  class Doc < Mustache
    include Config::Mixin

    self.template_name = 'doc'

    def copyright
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
      config.objc_mode && config.hide_declarations != 'objc'
    end

    def language_stub
      objc_first? ? 'objc' : 'swift'
    end

    def module_version
      config.version_configured ? config.version : nil
    end

    def docs_title
      if config.title_configured
        config.title
      elsif config.version_configured
        # Fake version for integration tests
        version = ENV['JAZZY_FAKE_MODULE_VERSION'] || config.version
        "#{config.module_name} #{version} Docs"
      else
        "#{config.module_name} Docs"
      end
    end

    def enable_katex
      Markdown.has_math
    end
  end
end
