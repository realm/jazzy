# frozen_string_literal: true

module Jazzy
  module SymbolGraph
    # An ExtKey identifies an extension of a type, made up of the USR of
    # the type and the constraints of the extension.  With Swift 5.9 extension
    # symbols, the USR is the 'fake' USR invented by symbolgraph to solve the
    # same problem as this type, which means less merging takes place.
    class ExtKey
      attr_accessor :usr
      attr_accessor :constraints_text

      def initialize(usr, constraints)
        self.usr = usr
        self.constraints_text = constraints.map(&:to_swift).join
      end

      def hash_key
        usr + constraints_text
      end

      def eql?(other)
        hash_key == other.hash_key
      end

      def hash
        hash_key.hash
      end
    end

    class ExtSymNode
      def ext_key
        ExtKey.new(usr, all_constraints.ext)
      end
    end
  end
end
