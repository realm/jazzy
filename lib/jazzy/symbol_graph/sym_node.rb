# frozen_string_literal: true

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
    # rubocop:disable Metrics/ClassLength
    class SymNode < BaseNode
      attr_accessor :symbol
      attr_writer :override
      attr_writer :protocol_requirement
      attr_writer :unlisted
      attr_accessor :superclass_name

      def override?
        @override
      end

      def protocol_requirement?
        @protocol_requirement
      end

      def top_level_decl?
        !@unlisted && parent.nil?
      end

      def initialize(symbol)
        self.symbol = symbol
        super()
      end

      def qualified_name
        symbol.path_components.join('.')
      end

      def parent_qualified_name
        symbol.path_components[0...-1].join('.')
      end

      def protocol?
        symbol.kind.end_with?('protocol')
      end

      def actor?
        symbol.kind.end_with?('actor')
      end

      def constraints
        symbol.constraints
      end

      # Add another SymNode as a member if possible.
      # It must go in an extension if either:
      #  - it has different generic constraints to us; or
      #  - we're a protocol and it's a default impl / ext method
      def try_add_child(node, unique_context_constraints)
        unless unique_context_constraints.empty? &&
               (!protocol? || node.protocol_requirement?)
          return false
        end

        add_child(node)
        true
      end

      # The `Constraint`s on this decl that are both:
      # 1. Unique, ie. not just inherited from its context; and
      # 2. Constraining the *context's* gen params rather than our own.
      def unique_context_constraints(context)
        return symbol.constraints unless context

        new_generic_type_params =
          symbol.generic_type_params - context.symbol.generic_type_params

        (symbol.constraints - context.symbol.constraints)
          .select { |con| con.type_names.disjoint?(new_generic_type_params) }
      end

      # Messy check whether we need to fabricate an extension for a protocol
      # conformance: don't bother if it's already in the type declaration.
      def conformance?(protocol)
        return false unless symbol.declaration =~ /(?<=:).*?(?=(where|$))/

        Regexp.last_match[0] =~ /\b#{protocol}\b/
      end

      # Generate the 'where' clause for the declaration
      def where_clause
        parent_constraints = parent&.constraints || []
        (constraints - parent_constraints).to_where_clause
      end

      def inherits_clause
        return '' unless superclass_name

        " : #{superclass_name}"
      end

      # approximately...
      def async?
        symbol.declaration =~ /\basync\b[^)]*$/
      end

      def full_declaration
        symbol.attributes
          .append(symbol.declaration + inherits_clause + where_clause)
          .join("\n")
      end

      # rubocop:disable Metrics/MethodLength
      def to_sourcekit
        declaration = full_declaration
        xml_declaration = "<swift>#{CGI.escapeHTML(declaration)}</swift>"

        hash = {
          'key.kind' => symbol.kind,
          'key.usr' => symbol.usr,
          'key.name' => symbol.name,
          'key.accessibility' => symbol.acl,
          'key.parsed_decl' => declaration,
          'key.annotated_decl' => xml_declaration,
          'key.symgraph_async' => async?,
        }
        if docs = symbol.doc_comments
          hash['key.doc.comment'] = docs
          hash['key.doc.full_as_xml'] = ''
        end
        if params = symbol.parameter_names
          hash['key.doc.parameters'] =
            params.map { |name| { 'name' => name } }
        end
        if location = symbol.location
          hash['key.filepath'] = location[:filename]
          hash['key.doc.line'] = location[:line] + 1
          hash['key.doc.column'] = location[:character] + 1
        end
        unless children.empty?
          hash['key.substructure'] = children_to_sourcekit
        end
        hash['key.symgraph_spi'] = true if symbol.spi

        hash
      end
      # rubocop:enable Metrics/MethodLength

      # Sort order - by symbol
      include Comparable

      def <=>(other)
        symbol <=> other.symbol
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
