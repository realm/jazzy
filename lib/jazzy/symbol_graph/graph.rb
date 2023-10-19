# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Jazzy
  module SymbolGraph
    # A Graph is the coordinator to import a symbolgraph json file.
    # Deserialize it to Symbols and Relationships, then rebuild
    # the AST shape using SymNodes and ExtNodes and extract SourceKit json.
    class Graph
      attr_accessor :module_name # Our module
      attr_accessor :ext_module_name # Module being extended
      attr_accessor :symbol_nodes # usr -> SymNode
      attr_accessor :relationships # [Relationship]
      attr_accessor :ext_nodes # (usr, constraints) -> ExtNode

      # Parse the JSON into flat tables of data
      def initialize(json, module_name, ext_module_name)
        self.module_name = module_name
        self.ext_module_name = ext_module_name
        graph = JSON.parse(json, symbolize_names: true)

        self.symbol_nodes = {}
        self.ext_nodes = {}

        graph[:symbols].each do |hash|
          symbol = Symbol.new(hash)
          if symbol.extension?
            node = ExtSymNode.new(symbol)
            ext_nodes[node.ext_key] = node
          else
            symbol_nodes[symbol.usr] = SymNode.new(symbol)
          end
        end

        self.relationships =
          graph[:relationships].map { |hash| Relationship.new(hash) }
      end

      # ExtNode index.  ExtKey (type USR, extension constraints) -> ExtNode.
      # This minimizes the number of extensions

      def add_ext_member(type_usr, member_node, constraints)
        key = ExtKey.new(type_usr, constraints.ext)
        if ext_node = ext_nodes[key]
          ext_node.add_child(member_node)
        else
          ext_nodes[key] =
            ExtNode.new_for_member(type_usr, member_node, constraints)
        end
      end

      def add_ext_conformance(type_usr,
                              type_name,
                              protocol,
                              constraints)
        key = ExtKey.new(type_usr, constraints.ext)
        if ext_node = ext_nodes[key]
          ext_node.add_conformance(protocol)
        else
          ext_nodes[key] =
            ExtNode.new_for_conformance(type_usr,
                                        type_name,
                                        protocol,
                                        constraints)
        end
      end

      # Increasingly desparate ways to find the name of the symbol
      # at the target end of a relationship
      def rel_target_name(rel, target_node)
        target_node&.symbol&.name ||
          rel.target_fallback ||
          Jazzy::SymbolGraph.demangle(rel.target_usr)
      end

      # Same for the source end.  Less help from the tool here
      def rel_source_name(rel, source_node)
        source_node&.qualified_name ||
          Jazzy::SymbolGraph.demangle(rel.source_usr)
      end

      # Protocol conformance is redundant if it's unconditional
      # and already expressed in the type's declaration.
      #
      # Skip implementation-detail conformances.
      def redundant_conformance?(rel, type, protocol)
        return false unless type

        (rel.constraints.empty? && type.conformance?(protocol)) ||
          (type.actor? && rel.actor_protocol?)
      end

      # source is a member/protocol requirement of target
      def rebuild_member(rel, source, target)
        return unless source

        source.protocol_requirement = rel.protocol_requirement?
        constraints =
          ExtConstraints.new(target&.constraints,
                             source.unique_context_constraints(target))

        # Add to its parent or invent an extension
        unless target&.try_add_child(source, constraints.ext)
          add_ext_member(rel.target_usr, source, constraints)
        end
      end

      # "source : target" either from type decl or ext decl
      def rebuild_conformance(rel, source, target)
        protocol_name = rel_target_name(rel, target)

        return if redundant_conformance?(rel, source, protocol_name)

        type_constraints = source&.constraints || []
        constraints =
          ExtConstraints.new(type_constraints,
                             rel.constraints - type_constraints)

        # Create an extension or enhance an existing one
        add_ext_conformance(rel.source_usr,
                            rel_source_name(rel, source),
                            protocol_name,
                            constraints)
      end

      # "source is a default implementation of protocol requirement target"
      def rebuild_default_implementation(_rel, source, target)
        return unless source

        unless target &&
               (target_parent = target.parent) &&
               target_parent.is_a?(SymNode)
          # Could probably figure this out with demangle, but...
          warn "Can't resolve membership of default implementation " \
            "#{source.symbol.usr}."
          source.unlisted = true
          return
        end
        constraints =
          ExtConstraints.new(target_parent.constraints,
                             source.unique_context_constraints(target_parent))

        add_ext_member(target_parent.symbol.usr,
                       source,
                       constraints)
      end

      # "source is a class that inherits from target"
      def rebuild_inherits(_rel, source, target)
        if source && target
          source.superclass_name = target.symbol.name
        end
      end

      # "References to fake_usr should be real_usr"
      def unalias_extensions(fake_usr, real_usr)
        ext_nodes.each_pair do |key, ext|
          if key.usr == fake_usr
            ext.real_usr = real_usr
          end
        end
      end

      # Process a structural relationship to link nodes
      def rebuild_rel(rel)
        source = symbol_nodes[rel.source_usr]
        target = symbol_nodes[rel.target_usr]

        case rel.kind
        when :memberOf, :optionalRequirementOf, :requirementOf
          rebuild_member(rel, source, target)

        when :conformsTo
          rebuild_conformance(rel, source, target)

        when :defaultImplementationOf
          rebuild_default_implementation(rel, source, target)

        when :inheritsFrom
          rebuild_inherits(rel, source, target)

        when :extensionTo
          unalias_extensions(rel.source_usr, rel.target_usr)
        end

        # don't seem to care about:
        # - overrides: not bothered, also unimplemented for protocols
      end

      # Rebuild the AST structure  and convert to SourceKit
      def to_sourcekit
        relationships.sort.each { |r| rebuild_rel(r) }

        root_symbol_nodes =
          symbol_nodes.values
            .select(&:top_level_decl?)
            .sort
            .map { |n| n.to_sourcekit(module_name) }

        root_ext_nodes =
          ext_nodes.values
            .sort
            .map { |n| n.to_sourcekit(module_name, ext_module_name) }
        {
          'key.diagnostic_stage' => 'parse',
          'key.substructure' => root_symbol_nodes + root_ext_nodes,
        }
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
