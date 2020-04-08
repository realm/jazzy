# rubocop:disable Style/ClassAndModuleChildren
module Jazzy::SymbolGraph
  class Relationship
    def initialize(hash)
      puts hash[:kind]
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
