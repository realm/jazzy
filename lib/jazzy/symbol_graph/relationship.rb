# frozen_string_literal: true

module Jazzy
  module SymbolGraph
    # A Relationship is a tidied-up SymbolGraph JSON object
    class Relationship
      attr_accessor :kind
      attr_accessor :source_usr
      attr_accessor :target_usr
      attr_accessor :target_fallback # can be nil
      attr_accessor :constraints # array, can be empty

      # Order matters: defaultImplementationOf after the protocols
      # have been defined; extensionTo after all the extensions have
      # been discovered.
      KINDS = %w[memberOf conformsTo overrides inheritsFrom
                 requirementOf optionalRequirementOf
                 defaultImplementationOf extensionTo].freeze

      KINDS_INDEX = KINDS.to_h { |i| [i.to_sym, KINDS.index(i)] }.freeze

      def protocol_requirement?
        %i[requirementOf optionalRequirementOf].include? kind
      end

      def default_implementation?
        kind == :defaultImplementationOf
      end

      def extension_to?
        kind == :extensionTo
      end

      # Protocol conformances added by compiler to actor decls that
      # users aren't interested in.
      def actor_protocol?
        %w[Actor Sendable].include?(target_fallback)
      end

      def initialize(hash)
        kind = hash[:kind]
        unless KINDS.include?(kind)
          raise "Unknown relationship kind '#{kind}'"
        end

        self.kind = kind.to_sym
        self.source_usr = hash[:source]
        self.target_usr = hash[:target]
        if fallback = hash[:targetFallback]
          # Strip the leading module name
          self.target_fallback = fallback.sub(/^.*?\./, '')
        end
        self.constraints = Constraint.new_list(hash[:swiftConstraints] || [])
      end

      # Sort order
      include Comparable

      def <=>(other)
        return 0 if kind == other.kind

        KINDS_INDEX[kind] <=> KINDS_INDEX[other.kind]
      end
    end
  end
end
