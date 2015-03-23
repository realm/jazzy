module Jazzy
  class SourceDeclaration
    class AccessControlLevel
      include Comparable

      attr_reader :level

      def initialize(accessibility)
        if accessibility == 'source.lang.swift.accessibility.private'
          @level = :private
        elsif accessibility == 'source.lang.swift.accessibility.internal'
          @level = :internal
        elsif accessibility == 'source.lang.swift.accessibility.public'
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
        if acl
          return acl
        end
        AccessControlLevel.public # We don't know what ACL this declaration is
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
        AccessControlLevel.new('source.lang.swift.accessibility.private')
      end

      def self.internal
        AccessControlLevel.new('source.lang.swift.accessibility.internal')
      end

      def self.public
        AccessControlLevel.new('source.lang.swift.accessibility.public')
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
