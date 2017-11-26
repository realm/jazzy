require 'commonmarker'
require 'jazzy/markdown/callout_scanner'

module Jazzy
  module Markdown
    class Renderer < CommonMarker::HtmlRenderer

      # Headers - add slug for linking and CSS class
      def header(node)
        text_slug = node.to_plaintext.gsub(/[^\w]+/, '-')
                        .downcase
                        .sub(/^-/, '')
                        .sub(/-$/, '')
        block do
          out('<h', node.header_level, ' ',
              'id="', text_slug, '" ',
              'class="heading">',
              :children,
              '</h', node.header_level, '>')
        end
      end
    end

    def self.renderer
      # Cannot reuse these .. need commonmarker PR
      Renderer.new
    end

    def self.copyright_renderer
      CopyrightRenderer.new
    end

    # In the copyright statement make links open in a new tab.
    class CopyrightRenderer < CommonMarker::HtmlRenderer
      def link(node)
        out('<a class="link" target="_blank" rel="external" href="',
            node.url.nil? ? '' : escape_href(node.url), '">',
            :children,
            '</a>')
      end
    end

    # @!group CommonMark config

    OPTIONS = [:SMART,                   # Smart quotes/dashes/dots
               :VALIDATE_UTF8,           # Filter invalid characters
               :LIBERAL_HTML_TAG].freeze # Pass through html

    EXTENSIONS = [:table,                # Tables
                  :strikethrough,        # Strikethrough (~)
                  :autolink].freeze      # Turn URLs into links

    def self.render_doc(markdown)
      CommonMarker.render_doc(markdown, OPTIONS, EXTENSIONS)
    end

    def self.renderDocHash(docHash)
      Hash[docHash.map { |key, doc| [key, renderer.render(doc)]}]
    end

    # @!group Public APIs

    class << self
      attr_reader :rendered_returns, :rendered_parameters
    end

    def self.render(markdown)
      doc = render_doc(markdown)
      scanner = CalloutScanner.new
      scanner.scan(doc)
      @rendered_returns =
        if scanner.returns_doc
          renderer.render(scanner.returns_doc)
        else
          nil
        end
      @rendered_parameters = renderDocHash(scanner.parameters_docs)
      renderer.render(doc)
    end

    def self.render_enum_case(enumcase)
      # something something munge munge
      nil
    end

    def self.render_copyright(markdown)
      copyright_renderer.render(render_doc(markdown))
    end
  end
end
