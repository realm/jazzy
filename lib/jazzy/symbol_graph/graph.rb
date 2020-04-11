module Jazzy
  module SymbolGraph
    # A Graph is the coordinator to import a symbolgraph json file.
    # Deserialize it to Symbols and Relationships, then rebuild
    # the AST shape using SymNodes and ExtNodes and extract SourceKit json.
    class Graph
      attr_accessor :module_name
      attr_accessor :symbol_nodes # usr -> SymNode
      attr_accessor :relationships # [Relationship]
      attr_accessor :ext_nodes # (usr, constraints) -> ExtNode

      # Parse the JSON into flat tables of data
      def initialize(json, module_name)
        self.module_name = module_name
        graph = JSON.parse(json, symbolize_names: true)

        self.symbol_nodes = {}
        graph[:symbols].each do |hash|
          symbol = Symbol.new(hash)
          symbol_nodes[symbol.usr] = SymNode.new(symbol)
        end

        self.relationships =
          graph[:relationships].map { |hash| Relationship.new(hash) }

        self.ext_nodes = {}
      end

      # ExtNode index.  (type USR, constraints) -> ExtNode.
      # This minimizes the number of extensions

      def ext_key(usr, constraints)
        usr + constraints.map(&:to_swift).join
      end

      def add_ext_member(type_usr, member_node, constraints)
        key = ext_key(type_usr, constraints)
        if ext_node = ext_nodes[key]
          ext_node.add_child(member_node)
        else
          ext_nodes[key] =
            ExtNode.new_for_member(type_usr, member_node, constraints)
        end
      end

      def add_ext_conformance(type_usr, type_name, protocol, constraints)
        key = ext_key(type_usr, constraints)
        if ext_node = ext_nodes[key]
          ext_node.add_conformance(protocol)
        else
          ext_nodes[key] = ExtNode.new_for_conformance(type_usr,
                                                       type_name,
                                                       protocol,
                                                       constraints)
        end
      end

      # Increasingly desparate ways to find the name of the symbol
      # at the target end of a relationship
      def rel_target_name(rel, target_node)
        (target_node && target_node.symbol.name) ||
          rel.target_fallback ||
          Jazzy::SymbolGraph.demangle(rel.target_usr)
      end

      # Same for the source end.  Less help from the tool here
      def rel_source_name(rel, source_node)
        (source_node && source_node.qualified_name) ||
          Jazzy::SymbolGraph.demangle(rel.source_usr)
      end

      # Protocol conformance is redundant if it's unconditional
      # and already expressed in the type's declaration.
      def redundant_conformance?(rel, type, protocol)
        type && rel.constraints.empty? && type.conformance?(protocol)
      end

      # Process a structural relationship to link nodes
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def rebuild_rel(rel)
        source = symbol_nodes[rel.source_usr]
        target = symbol_nodes[rel.target_usr]

        case rel.kind
        when :memberOf
          # source is a member of target
          return unless source

          context_constraints = source.unique_context_constraints(target)

          # Add to its parent or invent an extension
          unless target && target.try_add_child(source, context_constraints)
            add_ext_member(rel.target_usr, source, context_constraints)
          end

        when :conformsTo
          # "source : target" either from type decl or ext decl
          protocol_name = rel_target_name(rel, target)

          unless redundant_conformance?(rel, source, protocol_name)
            constraints =
              rel.constraints - ((source && source.symbol.constraints) || [])

            # Create an extension or enhance an existing one
            add_ext_conformance(rel.source_usr,
                                rel_source_name(rel, source),
                                protocol_name,
                                constraints)
          end
          # don't seem to care about:
          # - defaultImplementationOf: deduced in jazzy-real
          # - overrides: not bothered, also unimplemented for protocols
          # - inheritsFrom: not bothered
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      # Scan the relationships and mark symnodes that are
      # protocol reqs.  Return the other relationships
      def mark_and_reject_protocol_requirements
        relationships.select do |rel|
          next true unless rel.protocol_requirement?
          if node = symbol_nodes[rel.source_usr]
            node.protocol_req = true
          end
          false
        end
      end

      # Rebuild the AST structure  and convert to SourceKit
      def to_sourcekit
        mark_and_reject_protocol_requirements.each do |rel|
          rebuild_rel(rel)
        end

        root_symbol_nodes =
          symbol_nodes.values
                      .select { |n| n.parent.nil? }
                      .sort
                      .map(&:to_sourcekit)

        root_ext_nodes =
          ext_nodes.values
                   .sort
                   .map { |n| n.to_sourcekit(module_name) }
        {
          'key.diagnostic_stage' => 'parse',
          'key.substructure' => root_symbol_nodes + root_ext_nodes,
        }
      end
    end
  end
end
