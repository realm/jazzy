module Jazzy::Markdown
  # This class manipulates the markdown AST before it is turned into HTML.
  #
  # It spots "callouts" like `- warning:` and edits the markdown AST so
  # they show up as nice box-outs instead of bullet items.
  #
  # In :func mode it spots `returns` and `parameter` documentation and
  # separates them out from the document body for separate rendering.
  #
  # In :enum mode it spots all callout-like things, leaves them in the doc
  # body, and also makes them available for separate use.  See jazzy#XXX.
  #
  class CalloutScanner

    attr_reader :returns_doc, :params_docs, :enum_cases_docs

    def initialize(mode)
      fail "Bad mode" unless [:normal, :func, :enum].include?(mode)
      @mode = mode
      @returns_doc = nil
      @params_docs = {}
      @enum_cases_docs = {}
    end

    def scan(doc)
      doc.each do |child|
        if child.type == :list && child.list_type == :bullet_list
          check_callouts(child)
        end
      end
    end

    def check_callouts(list_node)
      list_node.each do |list_item_node|
        next unless list_item_node.type == :list_item
        para_node = list_item_node.first_child
        next unless para_node && para_node.type == :paragraph
        text_node = para_node.first_child
        next unless text_node && text_node.type == :text
        maybe_callout_line = text_node.string_content
        next unless maybe_callout_line =~
          /^\s*(?:(?<callout>\S+)|Callout\((?<callout>.+)\))\s*:/
        callout = Regexp.last_match[:callout]

        if callout == 'Parameters'
          params_list_node = para_node.next
          next unless params_list_node && params_list_node.type == :list
          params_list_node.each do |param_list_item_node|
            next unless param_list_item_node.type == :list_item
            param_para_node = param_list_item_node.first_child
            next unless param_para_node && param_para_node.type == :paragraph
            param_text_node = param_para_node.first_child
            next unless param_text_node && param_text_node.type == :text
            maybe_param_line = param_text_node.string_content
            next unless maybe_param_line =~ /^\s*(?<param>\S+)\s*:/
            puts("Found param #{Regexp.last_match[:param]}")
          end
          next
        end

        # Only do this part if decide to process callout...
        text_node.string_content =
            maybe_callout_line.sub(/^.*?#{callout}.*?:\s*/, '')

        # Callout on exclude list: throw away list_item_node
            # if config.exclude_callouts.includes(callout)
            #   list_item_node.delete
            #   next
            # end

        # Normal callout: reparent stuff
        # Custom callout: reparent stuff
            # if is_custom || normal_callouts.includes(callout)
            #   intro/body/outro dance as below
            #   list_item_node.delete
            #   next
            # end

        # Returns callout: reparent stuff to new :doc and stash, discard
            # @returns_doc = CommonMarker::Node.new(:document)
            # while node = list_item_node.first_child do
            #   @returns_doc_node.prepend_child(node)
            # end
            # list_item_node.delete

        # Parameter callout: reparent stuff to new :doc and stash, discard
            # Special regexp because 'parameter foo:'
            # @params_docs[param] = doc
            # list_item_node.delete

        # Parameters special callout: dig one layer down, stash each, discard

        # Set up html intro to callout
        html_in_node = CommonMarker::Node.new(:html)
        html_in_node.string_content =
          "<div class='aside aside-attention'>\n" +
          "<p class='aside-title'>#{callout}</p>"
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
  end
end
