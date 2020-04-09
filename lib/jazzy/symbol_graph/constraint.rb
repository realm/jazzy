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

      def self.decode(constraint)
        swift_spelling = KIND_MAP[constraint[:kind]]
        raise "Unknown conformance kind '#{kind}'" unless swift_spelling

        constraint[:lhs].sub(/^Self\./, '') +
          " #{swift_spelling} " +
          constraint[:rhs].sub(/^Self\./, '')
      end

      def self.decode_list(constraints)
        constraints.map do |constraint|
          decode(constraint)
        end.sort
      end

      # Swift protocols and reqs have an implementation/hidden conformance
      # to their own protocol: we don't want to think about this in docs.
      def self.decode_list_for_symbol(constraints, path_components)
        constraints.map do |constraint|
          if constraint[:lhs] == 'Self' &&
             constraint[:kind] == 'conformance' &&
             path_components.include?(constraint[:rhs])
            next nil
          end
          decode(constraint)
        end.compact.sort
      end
    end
  end
end
