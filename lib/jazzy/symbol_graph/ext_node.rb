module Jazzy
  module SymbolGraph
    # An ExtNode is a node of the reconstructed syntax tree representing
    # an extension that we fabricate to resolve certain relationships.
    class ExtNode < BaseNode
      attr_accessor :usr
      attr_accessor :name
      attr_accessor :type_constraints # array, can be empty
      attr_accessor :ext_constraints # array, can be empty
      attr_accessor :conformances # array, can be empty

      # Deduce an extension from a member of an unknown type or
      # of known type with additional constraints
      def self.new_for_member(type_usr,
                              member,
                              type_constraints,
                              ext_constraints)
        new(type_usr,
            member.parent_qualified_name,
            type_constraints,
            ext_constraints).tap { |o| o.add_child(member) }
      end

      # Deduce an extension from a protocol conformance for some type
      def self.new_for_conformance(type_usr,
                                   type_name,
                                   protocol,
                                   type_constraints,
                                   ext_constraints)
        new(type_usr, type_name, type_constraints, ext_constraints).tap do |o|
          o.add_conformance(protocol)
        end
      end

      private

      def initialize(usr, name, type_constraints, ext_constraints)
        self.usr = usr
        self.name = name
        self.type_constraints = type_constraints || []
        self.ext_constraints = ext_constraints
        self.conformances = []
        super()
      end

      public

      def constraints
        (ext_constraints + type_constraints).sort
      end

      def add_conformance(protocol)
        conformances.append(protocol).sort
      end

      def full_declaration
        decl = "extension #{name}"
        unless conformances.empty?
          decl += ' : ' + conformances.join(', ')
        end
        decl + ext_constraints.to_where_clause
      end

      def to_sourcekit(module_name)
        declaration = full_declaration
        xml_declaration = "<swift>#{CGI.escapeHTML(declaration)}</swift>"

        hash = {
          'key.kind' => 'source.lang.swift.decl.extension',
          'key.usr' => usr,
          'key.name' => name,
          'key.modulename' => module_name,
          'key.parsed_declaration' => declaration,
          'key.annotated_decl' => xml_declaration,
        }

        unless conformances.empty?
          hash['key.inheritedtypes'] = conformances.map do |conformance|
            { 'key.name' => conformance }
          end
        end

        unless children.empty?
          hash['key.substructure'] = children_to_sourcekit
        end

        hash
      end

      # Sort order - by type name then constraint
      include Comparable

      def sort_key
        name + constraints.map(&:to_swift).join
      end

      def <=>(other)
        sort_key <=> other.sort_key
      end
    end
  end
end
