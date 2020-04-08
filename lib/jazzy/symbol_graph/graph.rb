# rubocop:disable Style/ClassAndModuleChildren
module Jazzy::SymbolGraph
  class Graph
    attr_accessor :module_name
    attr_accessor :symbols
    attr_accessor :relationships

    def initialize(json, module_name)
      self.module_name = module_name
      graph = JSON.parse(json, symbolize_names: true)
      self.symbols = graph[:symbols].map { |h| Symbol.new(h) }.compact
      self.relationships =
        graph[:relationships].map { |h| Relationship.new(h) }.compact
    end

    def to_sourcekitten_hash
      {}
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
