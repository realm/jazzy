require 'commonmarker'
require 'jazzy/callout_scanner'

module Jazzy
  module Markdown
    class Renderer < CommonMarker::HtmlRenderer
      attr_accessor :default_language

      # Headers - add slug for linking and CSS class
      def header(node)
        text_slug = node.to_plaintext.gsub(/\W+/, '-')
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

      # Code blocks - add syntax highlighting
      def code_block(node)
        language = if node.fence_info && !node.fence_info.empty?
                     node.fence_info
                   else
                     default_language
                   end
        out(Highlighter.highlight_code_block(node.string_content, language))
      end
    end

    # Work around CMr renderers not being reusable
    class RendererWrapper
      attr_accessor :default_language

      def render(doc)
        cm_renderer = Renderer.new
        cm_renderer.default_language = default_language
        cm_renderer.render(doc)
      end
    end

    def self.renderer
      @renderer ||= RendererWrapper.new
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

    # CommonMark config

    OPTIONS = [:SMART,                   # Smart quotes/dashes/dots
               :VALIDATE_UTF8,           # Filter invalid characters
               :LIBERAL_HTML_TAG].freeze # Pass through html

    EXTENSIONS = [:table,                # Tables
                  :strikethrough,        # Strikethrough (~)
                  :autolink].freeze      # Turn URLs into links

    def self.render_doc(markdown)
      CommonMarker.render_doc(markdown, OPTIONS, EXTENSIONS)
    end

    # Interface

    class << self
      attr_reader :rendered_returns, :rendered_parameters
    end

    def self.render(markdown, default_language = nil)
      renderer.default_language = default_language

      doc = render_doc(markdown)
      scanner = CalloutScanner.new
      scanner.scan(doc)

      @rendered_returns =
        if scanner.returns_doc
          renderer.render(scanner.returns_doc)
        end

      @rendered_parameters = scanner.parameters_docs.map do |name, param_doc|
        {
          name: name,
          discussion: renderer.render(param_doc),
        }
      end

      renderer.render(doc)
    end

    def self.render_copyright(markdown)
      copyright_renderer.render(render_doc(markdown))
    end
  end
end
