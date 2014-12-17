module Jazzy
  class SourceDeclaration
    class AccessControlLevel
      include Comparable

      attr_reader :level

      def initialize(declaration_string)
        if declaration_string =~ /private\ /
          @level = :private
        elsif declaration_string =~ /public\ /
          @level = :public
        else
          @level = :internal
        end
      end

      def self.private
        AccessControlLevel.new('private ')
      end

      def self.internal
        AccessControlLevel.new('internal ')
      end

      def self.public
        AccessControlLevel.new('public ')
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
