require 'redcarpet'

module Jazzy
  class JazzyHTML < Redcarpet::Render::HTML
    def paragraph(text)
      "<p class=\"para\">#{text}</p>"
    end
  end

  def self.markdown
    @markdown ||= Redcarpet::Markdown.new(JazzyHTML, autolink: true)
  end
end
