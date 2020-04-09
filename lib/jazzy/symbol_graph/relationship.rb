module Jazzy
  module SymbolGraph
    # A Relationship is a tidied-up SymbolGraph JSON object
    class Relationship
      attr_accessor :kind
      attr_accessor :sourceUSR
      attr_accessor :targetUSR
      attr_accessor :targetFallback # can be nil
      attr_accessor :constraints # array, can be empty

      KINDS = %w[memberOf conformsTo defaultImplementationOf
                 overrides inheritsFrom requirementOf
                 optionalRequirementOf].freeze

      def initialize(hash)
        kind = hash[:kind]
        unless KINDS.include?(kind)
          raise "Unknown relationship kind '#{kind}'"
        end
        self.kind = kind
        self.sourceUSR = hash[:sourceUSR]
        self.targetUSR = hash[:targetUSR]
        self.targetFallback = hash[:targetFallback]
        self.constraints = Constraint.decode_list(hash[:swiftConstraints] || [])
      end
    end
  end
end
