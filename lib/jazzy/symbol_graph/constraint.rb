module Jazzy
  module SymbolGraph
    # Constraint is a tidied-up JSON object, used by both Symbol and
    # Relationship, and key to reconstructing extensions.
    class Constraint
      attr_accessor :kind
      attr_accessor :lhs
      attr_accessor :rhs

      KIND_MAP = {
        'conformance' => ':',
        'superclass' => ':',
        'sameType' => '==',
      }.freeze

      def initialize(hash)
        self.kind = KIND_MAP[hash[:kind]]
        raise "Unknown constraint kind '#{kind}'" unless kind
        self.lhs = hash[:lhs].sub(/^Self\./, '')
        self.rhs = hash[:rhs].sub(/^Self\./, '')
      end

      def to_swift
        "#{lhs} #{kind} #{rhs}"
      end

      # The first component of types in the constraint
      def type_names
        Set.new([lhs, rhs].map { |n| n.sub(/\..*$/, '') })
      end

      def self.new_list(hash_list)
        hash_list.map { |h| Constraint.new(h) }.sort.uniq
      end

      # Swift protocols and reqs have an implementation/hidden conformance
      # to their own protocol: we don't want to think about this in docs.
      def self.new_list_for_symbol(hash_list, path_components)
        hash_list.map do |hash|
          if hash[:lhs] == 'Self' &&
             hash[:kind] == 'conformance' &&
             path_components.include?(hash[:rhs])
            next nil
          end
          Constraint.new(hash)
        end.compact.sort.uniq
      end

      # Sort order - by Swift text
      include Comparable

      def <=>(other)
        to_swift <=> other.to_swift
      end

      alias eql? ==

      def hash
        to_swift.hash
      end
    end
  end
end

class Array
  def to_where_clause
    empty? ? '' : ' where ' + map(&:to_swift).join(', ')
  end
end
