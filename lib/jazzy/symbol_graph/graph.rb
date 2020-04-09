# rubocop:disable Style/ClassAndModuleChildren
module Jazzy::SymbolGraph
  class Graph
    attr_accessor :module_name
    attr_accessor :symbol_nodes
    attr_accessor :relationships

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
    end

    # Scan the relationships and mark symnodes that are
    # protocol reqs.  Return the other relationships.
    def mark_and_reject_protocol_requirements
      relationships.select do |rel|
        next true unless rel.protocol_requirement?
        if node = symbol_nodes[rel.source_usr]
          node.protocol_req = true
        end
        false
      end
    end

    def rebuild
      other_rels = mark_and_reject_protocol_requirements

      other_rels.each do |rel|
        case rel.kind
        when :memberOf
          # source is a member of target
          break unless source = symbol_nodes[rel.source_usr]

          if (target = symbol_nodes[rel.target_usr]) &&
             target.symbol.constraints == source.symbol.constraints &&
             # don't add default impls etc to protocols
             (!target.protocol? || source.protocol_req?)
            target.add_child(source)
          end
        end
      end
    end

    def to_sourcekit
      rebuild

      root_symbol_nodes =
        symbol_nodes.values
                    .select { |n| n.parent.nil? }
                    .sort
                    .map(&:to_sourcekit)
      {
        'key.diagnostic_stage' => 'parse',
        'key.substructure' => root_symbol_nodes
      }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
