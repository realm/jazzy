module Jazzy
  module SymbolGraph
    # Constraint is a tidied-up JSON object, used by both Symbol and
    # Relationship, and key to reconstructing extensions.
    class Constraint
      attr_accessor :kind
      attr_accessor :lhs
      attr_accessor :rhs

      private

      def initialize(kind, lhs, rhs)
        self.kind = kind # "==" or ":"
        self.lhs = lhs
        self.rhs = rhs
      end

      public

      KIND_MAP = {
        'conformance' => ':',
        'superclass' => ':',
        'sameType' => '==',
      }.freeze

      # Init from a JSON hash
      def self.new_hash(hash)
        kind = KIND_MAP[hash[:kind]]
        raise "Unknown constraint kind '#{kind}'" unless kind
        lhs = hash[:lhs].sub(/^Self\./, '')
        rhs = hash[:rhs].sub(/^Self\./, '')
        new(kind, lhs, rhs)
      end

      # Init from a Swift declaration fragment eg. 'A : B'
      def self.new_declaration(decl)
        decl =~ /^(.*?)\s*([:<=]+)\s*(.*)$/
        new(Regexp.last_match[2],
            Regexp.last_match[1],
            Regexp.last_match[3])
      end

      def to_swift
        "#{lhs} #{kind} #{rhs}"
      end

      # The first component of types in the constraint
      def type_names
        Set.new([lhs, rhs].map { |n| n.sub(/\..*$/, '') })
      end

      def self.new_list(hash_list)
        hash_list.map { |h| Constraint.new_hash(h) }.sort.uniq
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
          Constraint.new_hash(hash)
        end.compact
      end

      # Workaround Swift 5.3 bug with missing constraint rels
      def self.new_list_from_declaration(decl)
        decl.split(/\s*,\s*/).map { |cons| Constraint.new_declaration(cons) }
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
