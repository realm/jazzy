module Jazzy
  class SourceDeclaration
    class AccessControlLevel
      include Comparable

      attr_reader :level

      ACCESSIBILITY_PRIVATE = 'source.lang.swift.accessibility.private'.freeze
      ACCESSIBILITY_FILEPRIVATE =
        'source.lang.swift.accessibility.fileprivate'.freeze
      ACCESSIBILITY_INTERNAL = 'source.lang.swift.accessibility.internal'.freeze
      ACCESSIBILITY_PUBLIC = 'source.lang.swift.accessibility.public'.freeze
      ACCESSIBILITY_OPEN = 'source.lang.swift.accessibility.open'.freeze

      def initialize(accessibility)
        @level = case accessibility
                 when ACCESSIBILITY_PRIVATE then :private
                 when ACCESSIBILITY_FILEPRIVATE then :fileprivate
                 when ACCESSIBILITY_INTERNAL then :internal
                 when ACCESSIBILITY_PUBLIC then :public
                 when ACCESSIBILITY_OPEN then :open
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
        case declaration_string
        when /private\ / then private
        when /fileprivate\ / then fileprivate
        when /public\ / then public
        when /open\ / then open
        when /internal\ / then internal
        end
      end

      def self.from_human_string(string)
        case string.to_s.downcase
        when 'private' then private
        when 'fileprivate' then fileprivate
        when 'internal' then internal
        when 'public' then public
        when 'open' then open
        else raise "cannot initialize AccessControlLevel with '#{string}'"
        end
      end

      def self.private
        new(ACCESSIBILITY_PRIVATE)
      end

      def self.fileprivate
        new(ACCESSIBILITY_FILEPRIVATE)
      end

      def self.internal
        new(ACCESSIBILITY_INTERNAL)
      end

      def self.public
        new(ACCESSIBILITY_PUBLIC)
      end

      def self.open
        new(ACCESSIBILITY_OPEN)
      end

      LEVELS = {
        private: 0,
        fileprivate: 1,
        internal: 2,
        public: 3,
        open: 4,
      }.freeze

      def <=>(other)
        LEVELS[level] <=> LEVELS[other.level]
      end

      def included_levels
        LEVELS.select { |_, v| v >= LEVELS[level] }.keys
      end

      def excluded_levels
        LEVELS.select { |_, v| v < LEVELS[level] }.keys
      end
    end
  end
end
