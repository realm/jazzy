module Jazzy
  module SymbolGraph
    # Constraints show up in both Symbols and Relationships.
    # They're modelled with plain strings, just utilities here.
    class Constraint
      KIND_MAP = {
        'conformance' => ':',
        'superclass' => ':',
        'sameType' => '==',
      }.freeze

      def self.decode(hash)
        swift_spelling = KIND_MAP[hash[:kind]]
        raise "Unknown conformance kind '#{kind}'" unless swift_spelling

        hash[:lhs].sub(/^Self\./, '') +
          " #{swift_spelling} " +
          hash[:rhs].sub(/^Self\./, '')
      end

      def self.decode_for_symbol(hash, path_components)
        # Swift protocols and reqs have an implementation/hidden conformance
        # to their own protocol: we don't want to think about this in docs.
        if hash[:lhs] == 'Self' &&
           hash[:kind] == 'conformance' &&
           path_components.include?(hash[:rhs])
          return nil
        end
        decode(hash)
      end
    end
  end
end
