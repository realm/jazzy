# frozen_string_literal: true

require 'uri'

require 'jazzy/config'
require 'jazzy/source_declaration'
require 'jazzy/source_host'

module Jazzy
  class SourceModule
    attr_accessor :name
    attr_accessor :docs
    attr_accessor :doc_coverage
    attr_accessor :doc_structure
    attr_accessor :author_name
    attr_accessor :author_url
    attr_accessor :dash_url
    attr_accessor :host

    def initialize(options, docs, doc_structure, doc_coverage)
      self.docs = docs
      self.doc_structure = doc_structure
      self.doc_coverage = doc_coverage
      self.name = options.module_name
      self.author_name = options.author_name
      self.author_url = options.author_url
      self.host = SourceHost.create(options)
      return unless options.dash_url

      self.dash_url =
        "dash-feed://#{ERB::Util.url_encode(options.dash_url.to_s)}"
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
