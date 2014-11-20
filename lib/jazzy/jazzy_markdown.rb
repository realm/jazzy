require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

module Jazzy
  class JazzyHTML < Redcarpet::Render::HTML
    include Redcarpet::Render::SmartyPants
    include Rouge::Plugins::Redcarpet

    def paragraph(text)
      "<p class=\"para\">#{text}</p>"
    end

    def header(text, header_level)
      text_slug = text.gsub(/[^a-zA-Z0-9]+/, '_').downcase.sub(/^_/, '').sub(/_$/, '')

      "<a href='##{text_slug}' class='anchor' aria-hidden=true><span class='header-anchor'></span></a>" \
      "<h#{header_level} id='#{text_slug}'>#{text}</h#{header_level}>"
    end

    OPTIONS = {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      quote: true,
      strikethrough: true,
      space_after_headers: true,
    }.freeze
  end

  def self.markdown
    @markdown ||= Redcarpet::Markdown.new(JazzyHTML,  JazzyHTML::OPTIONS)
  end
end
