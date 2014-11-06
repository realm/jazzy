require 'redcarpet'

module Jazzy
  class JazzyHTML < Redcarpet::Render::HTML
    def paragraph(text)
      "<p class=\"para\">#{text}</p>"
    end

    OPTIONS = {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      quote: true,
      strikethrough: true,
    }.freeze
  end

  def self.markdown
    @markdown ||= Redcarpet::Markdown.new(JazzyHTML,  JazzyHTML::OPTIONS)
  end
end
