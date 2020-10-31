module Jazzy
  module SymbolGraph
    # The rebuilt syntax tree is made of nodes that either match
    # symbols or that we fabricate for extensions.  This is the common
    # treeishness.
    class BaseNode
      attr_accessor :children # array, can be empty
      attr_accessor :parent # can be nil

      def initialize
        self.children = []
      end

      def add_child(child)
        child.parent = self
        children.append(child)
      end

      def children_to_sourcekit
        children.sort.map(&:to_sourcekit)
      end
    end

    # A SymNode is a node of the reconstructed syntax tree holding a symbol.
    # It can turn itself into SourceKit and helps decode extensions.
    class SymNode < BaseNode
      attr_accessor :symbol
      attr_writer :override
      attr_writer :protocol_req

      def override?
        @override
      end

      def protocol_req?
        @protocol_req
      end

      def initialize(symbol)
        self.symbol = symbol
        super()
      end

      def qualified_name
        symbol.path_components.join('.')
      end

      def protocol?
        symbol.kind.end_with?('protocol')
      end

      # Messy check whether we need to fabricate an extension for a protocol
      # conformance: don't bother if it's already in the type declaration.
      def conformance?(protocol)
        return false unless symbol.declaration =~ /(?<=:).*?(?=(where|$))/
        Regexp.last_match[0] =~ /\b#{protocol}\b/
      end

      def full_declaration
        symbol.availability.append(symbol.declaration).join("\n")
      end

      # rubocop:disable Metrics/MethodLength
      def to_sourcekit
        declaration = full_declaration
        xml_declaration = "<swift>#{CGI.escapeHTML(declaration)}</swift>"

        hash = {
          'key.kind' => symbol.kind,
          'key.usr' =>  symbol.usr,
          'key.name' => symbol.name,
          'key.accessibility' => symbol.acl,
          'key.parsed_decl' => declaration,
          'key.annotated_decl' => xml_declaration,
        }
        if docs = symbol.doc_comments
          hash['key.doc.comment'] = docs
          hash['key.doc.full_as_xml'] = ''
        end
        if location = symbol.location
          hash['key.filepath'] = location[:filename]
          hash['key.doc.line'] = location[:line]
          hash['key.doc.column'] = location[:character]
        end
        unless children.empty?
          hash['key.substructure'] = children_to_sourcekit
        end

        hash
      end
      # rubocop:enable Metrics/MethodLength

      # Sort order - by symbol
      include Comparable

      def <=>(other)
        symbol <=> other.symbol
      end
    end
  end
end
