module Jazzy
  module SymbolGraph
    # A Relationship is a tidied-up SymbolGraph JSON object
    class Relationship
      attr_accessor :kind
      attr_accessor :source_usr
      attr_accessor :target_usr
      attr_accessor :target_fallback # can be nil
      attr_accessor :constraints # array, can be empty

      KINDS = %w[memberOf conformsTo defaultImplementationOf
                 overrides inheritsFrom requirementOf
                 optionalRequirementOf].freeze

      def protocol_requirement?
        %i[requirementOf optionalRequirementOf].include? kind
      end

      def initialize(hash)
        kind = hash[:kind]
        unless KINDS.include?(kind)
          raise "Unknown relationship kind '#{kind}'"
        end
        self.kind = kind.to_sym
        self.source_usr = hash[:source]
        self.target_usr = hash[:target]
        self.target_fallback = hash[:targetFallback]
        self.constraints = Constraint.decode_list(hash[:swiftConstraints] || [])
      end
    end
  end
end
