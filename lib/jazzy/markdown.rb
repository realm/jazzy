require 'commonmarker'

module Jazzy
  module Markdown

    def self.render(markdown_text)
      CommonMarker.render_html(markdown_text, :DEFAULT)
    end

    def self.rendered_returns
      nil
    end

    def self.rendered_parameters
      {}
    end

    def self.render_copyright(markdown_text)
      CommonMarker.render_html(markdown_text, :DEFAULT)
    end
  end
end
