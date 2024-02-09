# frozen_string_literal: true

require 'uri'

require 'jazzy/config'
require 'jazzy/source_declaration'
require 'jazzy/source_host'

module Jazzy
  # A cache of info that is common across all page templating, gathered
  # from other parts of the program.
  class SourceModule
    include Config::Mixin

    attr_accessor :readme_title
    attr_accessor :docs
    attr_accessor :doc_coverage
    attr_accessor :doc_structure
    attr_accessor :author_name
    attr_accessor :author_url
    attr_accessor :dash_feed_url
    attr_accessor :host

    def initialize(docs, doc_structure, doc_coverage, docset_builder)
      self.docs = docs
      self.doc_structure = doc_structure
      self.doc_coverage = doc_coverage
      self.readme_title =
        config.readme_title || config.module_names.first
      self.author_name = config.author_name
      self.author_url = config.author_url
      self.host = SourceHost.create(config)
      self.dash_feed_url = docset_builder.dash_feed_url
    end

    def all_declarations
      all_declarations = []
      visitor = lambda do |d|
        all_declarations.unshift(*d)
        d.map(&:children).each { |c| visitor[c] }
      end
      visitor[docs]
      all_declarations.reject { |doc| doc.name == 'index' }
    end
  end
end
