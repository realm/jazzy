require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

module Jazzy
  class JazzyHTML < Redcarpet::Render::HTML
    include Redcarpet::Render::SmartyPants
    include Rouge::Plugins::Redcarpet

    def header(text, header_level)
      text_slug = text.gsub(/[^a-zA-Z0-9]+/, '_')
        .downcase
        .sub(/^_/, '')
        .sub(/_$/, '')

      "<a href='##{text_slug}' class='anchor' aria-hidden=true>" \
        '<span class="header-anchor"></span>' \
      '</a>' \
      "<h#{header_level} id='#{text_slug}'>#{text}</h#{header_level}>\n"
    end

    SPECIAL_LIST_TYPES = %w(Attention
                            Author
                            Authors
                            Bug
                            Complexity
                            Copyright
                            Date
                            Experiment
                            Important
                            Invariant
                            Note
                            Parameter
                            Postcondition
                            Precondition
                            Remark
                            Requires
                            Returns
                            See
                            SeeAlso
                            Since
                            TODO
                            Throws
                            Version
                            Warning).freeze

    # rubocop:disable RegexpLiteral
    SPECIAL_LIST_TYPE_REGEX = %r{
      \A\s* # optional leading spaces
      (<p>\s*)? # optional opening p tag
      # any one of our special list types
      (#{SPECIAL_LIST_TYPES.map(&Regexp.method(:escape)).join('|')})
      [\s:] # followed by either a space or a colon
    }ix
    # rubocop:enable RegexpLiteral

    ELIDED_LI_TOKEN = '7wNVzLB0OYPL2eGlPKu8q4vITltqh0Y6DPZf659TPMAeYh49o'.freeze

    def list_item(text, _list_type)
      return ELIDED_LI_TOKEN if text =~ SPECIAL_LIST_TYPE_REGEX
      str = '<li>'
      str << text.strip
      str << "</li>\n"
    end

    def list(text, list_type)
      elided = text.gsub!(ELIDED_LI_TOKEN, '')
      return if text =~ /\A\s*\Z/ && elided
      str = "\n"
      str << (list_type == :ordered ? "<ol>\n" : "<ul>\n")
      str << text
      str << (list_type == :ordered ? "</ol>\n" : "</ul>\n")
    end

    OPTIONS = {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      quote: true,
      strikethrough: true,
      space_after_headers: false,
      tables: true,
    }.freeze
  end

  def self.markdown
    @markdown ||= Redcarpet::Markdown.new(JazzyHTML,  JazzyHTML::OPTIONS)
  end
end
