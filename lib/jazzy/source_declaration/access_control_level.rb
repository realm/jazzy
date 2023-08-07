# frozen_string_literal: true

module Jazzy
  class SourceDeclaration
    class AccessControlLevel
      include Comparable

      # Order matters
      LEVELS = %i[private fileprivate internal package public open].freeze

      LEVELS_INDEX = LEVELS.to_h { |i| [i, LEVELS.index(i)] }.freeze

      attr_reader :level

      def initialize(level)
        @level = level
      end

      # From a SourceKit accessibility string
      def self.from_accessibility(accessibility)
        return nil if accessibility.nil?

        if accessibility =~ /^source\.lang\.swift\.accessibility\.(.*)$/ &&
           (matched = Regexp.last_match(1).to_sym) &&
           !LEVELS_INDEX[matched].nil?
          return new(matched)
        end

        raise "cannot initialize AccessControlLevel with '#{accessibility}'"
      end

      # From a SourceKit declaration hash
      def self.from_doc(doc)
        return AccessControlLevel.internal if implicit_deinit?(doc)

        from_documentation_attribute(doc) ||
          from_accessibility(doc['key.accessibility']) ||
          from_doc_explicit_declaration(doc) ||
          AccessControlLevel.internal # fallback on internal ACL
      end

      # Workaround `deinit` being always technically public
      def self.implicit_deinit?(doc)
        doc['key.name'] == 'deinit' &&
          from_doc_explicit_declaration(doc).nil?
      end

      # From a Swift declaration
      def self.from_doc_explicit_declaration(doc)
        declaration = doc['key.parsed_declaration']
        LEVELS.each do |level|
          if declaration =~ /\b#{level}\b/
            return send(level)
          end
        end
        nil
      end

      # From a config instruction
      def self.from_human_string(string)
        normalized = string.to_s.downcase.to_sym
        if LEVELS_INDEX[normalized].nil?
          raise "cannot initialize AccessControlLevel with '#{string}'"
        end

        send(normalized)
      end

      # From a @_documentation(visibility:) attribute
      def self.from_documentation_attribute(doc)
        if doc['key.annotated_decl'] =~ /@_documentation\(\s*visibility\s*:\s*(\w+)/
          from_human_string(Regexp.last_match[1])
        end
      end

      # Define `AccessControlLevel.public` etc.

      LEVELS.each do |level|
        define_singleton_method(level) do
          new(level)
        end
      end

      # Comparing access levels

      def <=>(other)
        LEVELS_INDEX[level] <=> LEVELS_INDEX[other.level]
      end

      def included_levels
        LEVELS_INDEX.select { |_, v| v >= LEVELS_INDEX[level] }.keys
      end

      def excluded_levels
        LEVELS_INDEX.select { |_, v| v < LEVELS_INDEX[level] }.keys
      end
    end
  end
end
