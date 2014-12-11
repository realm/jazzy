require 'active_support/inflector'

module Jazzy
  class SourceDeclaration
    class Type
      DASH_TYPES = {
        'Class Method' => 'Method',
        'Class Variable' => 'Variable',
        'Class' => 'Class',
        'Constructor' => 'Constructor',
        'Destructor' => 'Method',
        'Global Variable' => 'Global',
        'Enum Element' => 'Element',
        'Enum' => 'Enum',
        'Extension' => 'Extension',
        'Function' => 'Function',
        'Instance Method' => 'Method',
        'Instance Variable' => 'Property',
        'Local Variable' => 'Variable',
        'Parameter' => 'Parameter',
        'Protocol' => 'Protocol',
        'Static Method' => 'Method',
        'Static Variable' => 'Variable',
        'Struct' => 'Struct',
        'Subscript' => 'Operator',
        'Typealias' => 'Type',
      }.freeze

      # SourceKit-provided token kinds along with their names
      # @todo Make sure this list is exhaustive for source.lang.swift.decl.*
      KIND_NAMES = {
        'source.lang.swift.decl.function.method.class' => 'Class Method',
        'source.lang.swift.decl.var.class' => 'Class Variable',
        'source.lang.swift.decl.class' => 'Class',
        'source.lang.swift.decl.function.constructor' => 'Constructor',
        'source.lang.swift.decl.function.destructor' => 'Destructor',
        'source.lang.swift.decl.var.global' => 'Global Variable',
        'source.lang.swift.decl.enumelement' => 'Enum Element',
        'source.lang.swift.decl.enum' => 'Enum',
        'source.lang.swift.decl.extension' => 'Extension',
        'source.lang.swift.decl.function.free' => 'Function',
        'source.lang.swift.decl.function.method.instance' => 'Instance Method',
        'source.lang.swift.decl.var.instance' => 'Instance Variable',
        'source.lang.swift.decl.var.local' => 'Local Variable',
        'source.lang.swift.decl.var.parameter' => 'Parameter',
        'source.lang.swift.decl.protocol' => 'Protocol',
        'source.lang.swift.decl.function.method.static' => 'Static Method',
        'source.lang.swift.decl.var.static' => 'Static Variable',
        'source.lang.swift.decl.struct' => 'Struct',
        'source.lang.swift.decl.function.subscript' => 'Subscript',
        'source.lang.swift.decl.typealias' => 'Typealias',
      }.freeze

      def self.all
        KIND_NAMES.keys.map { |k| new(k) }
      end

      attr_reader :kind

      def initialize(kind)
        @kind = kind
      end

      def dash_type
        DASH_TYPES[name] || name
      end

      def name
        KIND_NAMES[kind]
      end

      def plural_name
        name.pluralize
      end

      def mark?
        kind == 'source.lang.swift.syntaxtype.comment.mark'
      end

      def declaration?
        kind =~ /^source\.lang\.swift\.decl\..*/
      end

      def self.overview
        Type.new('Overview')
      end

      def hash
        kind.hash
      end

      alias_method :equals, :==
      def ==(other)
        other && kind == other.kind
      end
    end
  end
end
