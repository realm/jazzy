module Jazzy::Markdown
  # This code manipulates the markdown AST before it is turned into HTML to
  # change eg. `- warning:` from list-items to box-outs, and to separate returns
  # and parameters documentation.

  class CommonMarker::Node
    # Extensions to help identify and process callouts.
    # A callout may exist when there is a List->ListItem->Para->Text node
    # hierarchy and the text matches a certain format.

    attr_reader :callout_param_name

    # Four slightly different formats wrapped up here:
    #   Callout(XXXX XXXX):YYYY
    #   Parameter XXXX: YYYY   (Swift)
    #   Parameter: XXXX YYYY   (ObjC via SourceKitten)
    #   XXXX:YYYYY
    def callout_parts
      if string_content =~ /\A\s*Callout\((.+)\)\s*:\s*(.*)\Z/mi
        @callout_custom = $1
        @callout_rest = $2
      elsif string_content =~ /\A\s*Parameter\s+(\S+)\s*:\s*(.*)\Z/mi ||
        string_content =~ /A\s*Parameter\s*:\s*(\S+)\s*(.*)\Z/mi
        @callout_param_name = $1
        @callout_rest = $2
      elsif string_content =~ /\A\s*(\S+)\s*:\s*(.*)\Z/mi
        @callout_type = $1
        @callout_rest = $2
      end
      @callout_rest
    end

    def callout_custom?
      @callout_custom
    end

    def callout_type
      @callout_type || @callout_custom
    end

    def callout_param?
      !@callout_param_name.nil?
    end

    # Edit the node to leave just the callout body
    def remove_callout_type!
      string_content = @callout_rest
    end

    # Iterator vending |list_item_node, text_node| for callout-looking children
    def each_callout
      return unless type == :list && list_type == :bullet_list
      each do |child_node|
        next unless child_node.type == :list_item
        para_node = child_node.first_child
        next unless para_node && para_node.type == :paragraph
        text_node = para_node.first_child
        next unless text_node && text_node.type == :text
        yield child_node, text_node if text_node.callout_parts
      end
    end
  end

  class CalloutScanner
    attr_reader :returns_doc, :parameters_docs, :enum_cases_docs

    def initialize
      @returns_doc = nil
      @parameters_docs = {}
      @enum_cases_docs = {}
    end

    def scan(doc)
      doc.each do |child|
        child.each_callout do |list_item_node, text_node|
          callout = text_node.callout_type

          if callout == 'Parameters'
            params_list_node = text_node.parent.next
            next unless params_list_node
            params_list_node.each_callout do |param_list_item_node, param_text_node|
              puts("Found param #{param_text_node.callout_type}")
            end
            next
          end

          # Only do this part if decide to process callout...
          text_node.remove_callout_type!

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
          child.insert_before(html_in_node)

        # Body of the callout
          while node = list_item_node.first_child do
            child.insert_before(node)
          end
          list_item_node.delete

          # HTML outro
          html_out_node = CommonMarker::Node.new(:html)
          html_out_node.string_content = '</div>'
          child.insert_before(html_out_node)
        end

        # Finally chuck the list if nothing left inside
        child.delete unless child.first_child 
      end
    end
  end
end
