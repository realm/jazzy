module CommonMarker
  class Node
    # Extensions to help identify and process callouts.
    # A callout may exist when there is a List->ListItem->Para->Text node
    # hierarchy and the text matches a certain format.

    # List of Swift callouts, excluding param/returns.
    # Plus 'example' from playgrounds.
    # https://github.com/apple/swift/blob/master/include/swift/Markup/SimpleFields.def
    NORMAL_CALLOUTS = %w[attention
                         author
                         authors
                         bug
                         complexity
                         copyright
                         date
                         experiment
                         important
                         invariant
                         localizationkey
                         mutatingvariant
                         nonmutatingvariant
                         note
                         postcondition
                         precondition
                         remark
                         remarks
                         throws
                         requires
                         seealso
                         since
                         tag
                         todo
                         version
                         warning
                         keyword
                         recommended
                         recommendedover
                         example].freeze

    attr_reader :callout_param_name

    # Four slightly different formats wrapped up here:
    #   Callout(XXXX XXXX):YYYY
    #   Parameter XXXX: YYYY   (Swift)
    #   Parameter: XXXX YYYY   (ObjC via SourceKitten)
    #   XXXX:YYYYY
    def callout_parts
      if string_content =~ /\A\s*callout\((.+)\)\s*:\s*(.*)\Z/mi
        @callout_custom = Regexp.last_match(1)
      elsif string_content =~ /\A\s*parameter\s+(\S+)\s*:\s*(.*)\Z/mi ||
            string_content =~ /A\s*parameter\s*:\s*(\S+)\s*(.*)\Z/mi
        @callout_param_name = Regexp.last_match(1)
      elsif string_content =~ /\A\s*(\S+)\s*:\s*(.*)\Z/mi
        @callout_type = Regexp.last_match(1)
      end
      @callout_rest = Regexp.last_match(2)
    end

    def callout_custom?
      @callout_custom
    end

    def callout_normal?
      @callout_type && NORMAL_CALLOUTS.include?(@callout_type.downcase)
    end

    def callout_type
      @callout_type || @callout_custom || ('parameter' if callout_param?)
    end

    def callout_param?
      @callout_param_name
    end

    def callout_parameters?
      callout_type.casecmp('parameters') == 0
    end

    def callout_returns?
      callout_type.casecmp('returns') == 0
    end

    # Edit the node to leave just the callout body
    def remove_callout_type!
      self.string_content = @callout_rest
    end

    # Iterator vending |list_item_node, text_node| for callout-looking children
    #
    # rubocop:disable Metrics/CyclomaticComplexity
    def each_callout
      each do |child_node|
        next unless child_node.type == :list_item
        para_node = child_node.first_child
        next unless para_node && para_node.type == :paragraph
        text_node = para_node.first_child
        next unless text_node && text_node.type == :text
        yield child_node, text_node if text_node.callout_parts
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end

module Jazzy::Markdown
  # This class manipulates the markdown AST before it is turned into HTML to
  # change eg. `- warning:` from list-items to box-outs and to separate returns
  # and parameters documentation.

  class CalloutScanner
    attr_reader :returns_doc, :parameters_docs

    def initialize
      @returns_doc = nil
      @parameters_docs = {}
    end

    # Deal with callouts on a top-level markdown doc
    def scan(doc)
      doc.each do |child|
        next unless child.type == :list && child.list_type == :bullet_list

        child.each_callout { |li, t| scan_callout(child, li, t) }
        child.delete unless child.first_child
      end
    end

    private

    # Deal with any top-level callout-looking thing
    #
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def scan_callout(list_node, list_item_node, text_node)
      if text_node.callout_param?
        @parameters_docs[text_node.callout_param_name] =
          extract_callout(list_item_node, text_node)
      elsif text_node.callout_parameters?
        params_list_node = text_node.parent.next
        scan_parameters(list_item_node, params_list_node) if params_list_node
      elsif text_node.callout_returns?
        @returns_doc = extract_callout(list_item_node, text_node)
      elsif text_node.callout_custom? || text_node.callout_normal?
        create_callout(list_node, list_item_node, text_node)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # Deal with 'parameters:' nesting - all children are param callouts
    def scan_parameters(list_item_node, params_list_node)
      params_list_node.each_callout do |param_list_item_node, param_text_node|
        @parameters_docs[param_text_node.callout_type] =
          extract_callout(param_list_item_node, param_text_node)
      end
      list_item_node.delete
    end

    # Create a normal callout by adding html nodes for the div
    # and moving the content up before the list.
    def create_callout(list_node, list_item_node, text_node)
      # HTML intro
      html_in_node = CommonMarker::Node.new(:html)

      css_class = text_node.callout_type.downcase.gsub(/\W+/, '-')
      title = text_node.callout_type.humanize
      html_in_node.string_content =
        "<div class='aside aside-#{css_class}'>\n" \
        "<p class='aside-title'>#{title}</p>"
      list_node.insert_before(html_in_node)

      # Body of the callout
      text_node.remove_callout_type!
      while node = list_item_node.first_child
        list_node.insert_before(node)
      end
      list_item_node.delete

      # HTML outro
      html_out_node = CommonMarker::Node.new(:html)
      html_out_node.string_content = '</div>'
      list_node.insert_before(html_out_node)
    end

    # Create a separate markdown doc for returns/param docs
    def extract_callout(list_item_node, text_node)
      doc_node = CommonMarker::Node.new(:document)
      text_node.remove_callout_type!
      while node = list_item_node.first_child
        doc_node.append_child(node)
      end
      list_item_node.delete
      doc_node
    end
  end
end
