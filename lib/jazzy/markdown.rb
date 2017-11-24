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

    def self.docHashToHtml(docHash)
      Hash[docHash.map { |key, doc| [key, Renderer.new.render(doc)]}]
    end

    # @!group Public APIs

    def self.render(markdown)
      doc = render_doc(markdown)
      CalloutScanner.new(:normal).scan(doc)
      Renderer.new.render(doc)
    end

    class << self
      attr_reader :rendered_returns, :rendered_parameters, :rendered_enum_cases
    end

    def self.render_func(markdown)
      doc = render_doc(markdown)
      scanner = CalloutScanner.new(:func)
      scanner.scan(doc)
      @rendered_returns = Renderer.new.render(scanner.returns_doc)
      @rendered_parameters = docHashToHtml(scanner.parameters_docs)
      Renderer.new.render(doc)
    end

    def self.render_enum(markdown)
      doc = render_doc(markdown)
      scanner = CalloutScanner.new(:enum)
      scanner.scan(doc)
      body_html = Renderer.new.render(doc)
      @rendered_enum_cases = docHashToHtml(scanner.enum_cases_docs)
      body_html
    end

    def self.render_copyright(markdown)
      CopyrightRenderer.new.render(render_doc(markdown))
    end
  end
end
