module Jazzy
  class SourceDeclaration
    class AccessControlLevel
      include Comparable

      attr_reader :level

      ACCESSIBILITY_PRIVATE  = 'source.lang.swift.accessibility.private'
      ACCESSIBILITY_INTERNAL = 'source.lang.swift.accessibility.internal'
      ACCESSIBILITY_PUBLIC   = 'source.lang.swift.accessibility.public'

      def initialize(accessibility)
        @level = case accessibility
                 when ACCESSIBILITY_PRIVATE then :private
                 when ACCESSIBILITY_INTERNAL then :internal
                 when ACCESSIBILITY_PUBLIC then :public
                 else
                   raise 'cannot initialize AccessControlLevel with ' \
                     "'#{accessibility}'"
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
        # rubocop:disable Style/EmptyLinesAroundAccessModifier
        case declaration_string
        when /private\ / then private
        when /public\ / then public
        when /internal\ / then internal
        end
        # rubocop:enable Style/EmptyLinesAroundAccessModifier
      end

      def self.from_human_string(string)
        # rubocop:disable Style/EmptyLinesAroundAccessModifier
        case string.to_s.downcase
        when 'private' then private
        when 'internal' then internal
        when 'public' then public
        else raise "cannot initialize AccessControlLevel with '#{string}'"
        end
        # rubocop:enable Style/EmptyLinesAroundAccessModifier
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
