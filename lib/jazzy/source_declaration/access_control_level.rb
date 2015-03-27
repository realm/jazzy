module Jazzy
  class SourceDeclaration
    class AccessControlLevel
      include Comparable

      attr_reader :level

      ACCESSIBILITY_PRIVATE  = 'source.lang.swift.accessibility.private'
      ACCESSIBILITY_INTERNAL = 'source.lang.swift.accessibility.internal'
      ACCESSIBILITY_PUBLIC   = 'source.lang.swift.accessibility.public'

      def initialize(accessibility)
        if accessibility == ACCESSIBILITY_PRIVATE
          @level = :private
        elsif accessibility == ACCESSIBILITY_INTERNAL
          @level = :internal
        elsif accessibility == ACCESSIBILITY_PUBLIC
          @level = :public
        end
      end

      def self.from_doc(doc)
        accessibility = doc['key.accessibility']
        if accessibility
          acl = new(accessibility)
          if acl
            return acl
          end
        end
        acl = from_explicit_declaration(doc['key.parsed_declaration'])
        acl || AccessControlLevel.public # fallback on public ACL
      end

      def self.from_explicit_declaration(declaration_string)
        if declaration_string =~ /private\ /
          return AccessControlLevel.private
        elsif declaration_string =~ /public\ /
          return AccessControlLevel.public
        elsif declaration_string =~ /internal\ /
          return AccessControlLevel.internal
        end
      end

      def self.private
        new(ACCESSIBILITY_PRIVATE)
      end

      def self.internal
        new(ACCESSIBILITY_INTERNAL)
      end

      def self.public
        new(ACCESSIBILITY_PUBLIC)
      end

      LEVELS = {
        private: 0,
        internal: 1,
        public: 2,
      }.freeze

      def <=>(other)
        LEVELS[level] <=> LEVELS[other.level]
      end
    end
  end
end
