require 'commonmarker'

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

    def self.check_callouts(doc_node, list_node)
      list_node.each do |list_item_node|
        next unless list_item_node.type == :list_item
        para_node = list_item_node.first_child
        next unless para_node && para_node.type == :paragraph
        text_node = para_node.first_child
        next unless text_node && text_node.type == :text
        maybe_callout_line = text_node.string_content
        next unless maybe_callout_line =~ /^\s*Attention\s*:/
        text_node.string_content =
          maybe_callout_line.sub(/Attention\s*:\s*/, '')

        # Set up html intro to callout
        html_in_node = CommonMarker::Node.new(:html)
        html_in_node.string_content =
          "<div class='aside aside-attention'>\n" +
          "<p class='aside-title'>Attention</p>"
        list_node.insert_before(html_in_node)

        # Body of the callout
        while node = list_item_node.first_child do
          list_node.insert_before(node)
        end
        list_item_node.delete

        # HTML outro
        html_out_node = CommonMarker::Node.new(:html)
        html_out_node.string_content = '</div>'
        list_node.insert_before(html_out_node)
      end

      # Finally chuck the list if nothing left inside
      list_node.delete unless list_node.first_child 
    end

    # @!group Public APIs

    def self.render(markdown)
      doc = render_doc(markdown)
      doc.each do |child|
        check_callouts(doc, child) if child.type == :list
      end
      Renderer.new.render(doc)
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
