require 'active_support/inflector'

module Jazzy
  class SourceDeclaration
    # rubocop:disable Metrics/ClassLength
    class Type
      def self.all
        TYPES.keys.map { |k| new(k) }
      end

      attr_reader :kind

      def initialize(kind)
        @kind = kind
        @type = TYPES[kind]
      end

      def dash_type
        @type && @type[:dash]
      end

      def name
        @type && @type[:jazzy]
      end

      def plural_name
        name.pluralize
      end

      def mark?
        kind == 'source.lang.swift.syntaxtype.comment.mark'
      end

      def should_document?
        declaration? && !param?
      end

      def declaration?
        kind =~ /^source\.lang\.swift\.decl\..*/
      end

      def param?
        kind == 'source.lang.swift.decl.var.parameter' ||
          kind == 'source.lang.swift.decl.var.local'
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

      TYPES = {
        'source.lang.swift.decl.function.method.class' => {
          jazzy: 'Class Method',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.class' => {
          jazzy: 'Class Variable',
          dash: 'Variable',
        }.freeze,
        'source.lang.swift.decl.class' => {
          jazzy: 'Class',
          dash: 'Class',
        }.freeze,
        'source.lang.swift.decl.function.constructor' => {
          jazzy: 'Constructor',
          dash: 'Constructor',
        }.freeze,
        'source.lang.swift.decl.function.destructor' => {
          jazzy: 'Destructor',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.global' => {
          jazzy: 'Global Variable',
          dash: 'Global',
        }.freeze,
        'source.lang.swift.decl.enumelement' => {
          jazzy: 'Enum Element',
          dash: 'Element',
        }.freeze,
        'source.lang.swift.decl.enum' => {
          jazzy: 'Enum',
          dash: 'Enum',
        }.freeze,
        'source.lang.swift.decl.extension' => {
          jazzy: 'Extension',
          dash: 'Extension',
        }.freeze,
        'source.lang.swift.decl.function.free' => {
          jazzy: 'Function',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.method.instance' => {
          jazzy: 'Instance Method',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.instance' => {
          jazzy: 'Instance Variable',
          dash: 'Property',
        }.freeze,
        'source.lang.swift.decl.var.local' => {
          jazzy: 'Local Variable',
          dash: 'Variable',
        }.freeze,
        'source.lang.swift.decl.var.parameter' => {
          jazzy: 'Parameter',
          dash: 'Parameter',
        }.freeze,
        'source.lang.swift.decl.protocol' => {
          jazzy: 'Protocol',
          dash: 'Protocol',
        }.freeze,
        'source.lang.swift.decl.function.method.static' => {
          jazzy: 'Static Method',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.static' => {
          jazzy: 'Static Variable',
          dash: 'Variable',
        }.freeze,
        'source.lang.swift.decl.struct' => {
          jazzy: 'Struct',
          dash: 'Struct',
        }.freeze,
        'source.lang.swift.decl.function.subscript' => {
          jazzy: 'Subscript',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.typealias' => {
          jazzy: 'Typealias',
          dash: 'Alias',
        }.freeze,
      }.freeze
    end
    # rubocop:enable Metrics/ClassLength
  end
end
