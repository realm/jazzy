# frozen_string_literal: true

require 'set'

module Jazzy
  module SymbolGraph
    # For extensions we need to track constraints of the extended type
    # and the constraints introduced by the extension.
    class ExtConstraints
      attr_accessor :type # array
      attr_accessor :ext # array

      # all constraints inherited by members of the extension
      def merged
        (type + ext).sort
      end

      def initialize(type_constraints, ext_constraints)
        self.type = type_constraints || []
        self.ext = ext_constraints || []
      end
    end

    # An ExtNode is a node of the reconstructed syntax tree representing
    # an extension that we fabricate to resolve certain relationships.
    class ExtNode < BaseNode
      attr_accessor :usr
      attr_accessor :real_usr
      attr_accessor :name
      attr_accessor :all_constraints # ExtConstraints
      attr_accessor :conformances # set, can be empty

      # Deduce an extension from a member of an unknown type or
      # of known type with additional constraints
      def self.new_for_member(type_usr,
                              member,
                              constraints)
        new(type_usr,
            member.parent_qualified_name,
            constraints).tap { |o| o.add_child(member) }
      end

      # Deduce an extension from a protocol conformance for some type
      def self.new_for_conformance(type_usr,
                                   type_name,
                                   protocol,
                                   constraints)
        new(type_usr, type_name, constraints).tap do |o|
          o.add_conformance(protocol)
        end
      end

      private

      def initialize(usr, name, constraints)
        self.usr = usr
        self.name = name
        self.all_constraints = constraints
        self.conformances = Set.new
        super()
      end

      public

      def constraints
        all_constraints.merged
      end

      def add_conformance(protocol)
        conformances.add(protocol)
      end

      def full_declaration
        decl = "extension #{name}"
        unless conformances.empty?
          decl += " : #{conformances.sort.join(', ')}"
        end
        decl + all_constraints.ext.to_where_clause
      end

      def to_sourcekit(module_name, ext_module_name)
        declaration = full_declaration
        xml_declaration = "<swift>#{CGI.escapeHTML(declaration)}</swift>"

        hash = {
          'key.kind' => 'source.lang.swift.decl.extension',
          'key.usr' => real_usr || usr,
          'key.name' => name,
          'key.modulename' => ext_module_name,
          'key.parsed_declaration' => declaration,
          'key.annotated_decl' => xml_declaration,
        }

        unless conformances.empty?
          hash['key.inheritedtypes'] = conformances.sort.map do |conformance|
            { 'key.name' => conformance }
          end
        end

        add_children_to_sourcekit(hash, module_name)

        hash
      end

      # Sort order - by type name then constraint then conformances
      # Conformance check needed for stable order with Swift 5.9
      # extension symbols that can't merge as well as previously.
      include Comparable

      def sort_key
        name + constraints.map(&:to_swift).join + conformances.sort.join
      end

      def <=>(other)
        sort_key <=> other.sort_key
      end
    end

    # An ExtSymNode is an extension generated from a Swift 5.9 extension
    # symbol, for extensions of types from other modules only.
    class ExtSymNode < ExtNode
      attr_accessor :symbol

      def initialize(symbol)
        self.symbol = symbol
        super(symbol.usr, symbol.full_name,
              # sadly can't tell what constraints are inherited vs added
              ExtConstraints.new([], symbol.constraints))
      end

      def to_sourcekit(module_name, ext_module_name)
        hash = super
        symbol.add_to_sourcekit(hash)
      end
    end
  end
end
