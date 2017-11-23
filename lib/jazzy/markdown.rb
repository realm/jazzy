require 'commonmarker'

module Jazzy
  module Markdown

    class Renderer < CommonMarker::HtmlRenderer
    end

    # In the copyright statement make links open in a new tab.
    class CopyrightRenderer < CommonMarker::HtmlRenderer
      def link(node)
        out('<a class="link" target="_blank" rel="external" href="',
            node.url.nil? ? '' : escape_href(node.url),
            '">',
            :children,
            '</a>')
      end
    end

    OPTIONS = [:SMART,                   # Smart quotes/dashes/dots
               :VALIDATE_UTF8,           # Filter invalid characters
               :LIBERAL_HTML_TAG].freeze # Let html go through

    EXTENSIONS = [:table,                # Tables
                  :strikethrough,        # Strikethrough (~)
                  :autolink].freeze      # Turn URLs into links

    def self.render_doc(markdown)
      CommonMarker.render_doc(markdown, OPTIONS, EXTENSIONS)
    end

    def self.render(markdown)
      Renderer.new.render(render_doc(markdown))
    end

    def self.rendered_returns
      nil
    end

    def self.rendered_parameters
      {}
    end

    def self.render_copyright(markdown)
      CopyrightRenderer.new.render(render_doc(markdown))
    end
  end
end
