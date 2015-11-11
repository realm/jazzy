require 'jazzy/source_declaration/access_control_level'
require 'jazzy/source_declaration/type'

module Jazzy
  class SourceDeclaration
    # kind of declaration (e.g. class, variable, function)
    attr_accessor :type
    # static type of declared element (e.g. String.Type -> ())
    attr_accessor :typename

    # Element containing this declaration in the code
    attr_accessor :parent_in_code

    # Logical parent in the documentation. May differ from parent_in_code
    # because of top-level categories and merged extensions.
    attr_accessor :parent_in_docs

    # counterpart of parent_in_docs
    attr_accessor :children

    def children=(new_children)
      @children = new_children.freeze
      @children.each { |c| c.parent_in_docs = self }
    end

    # Chain of parent_in_code from top level to self. (Includes self.)
    def namespace_path
      namespace_ancestors + [self]
    end

    def namespace_ancestors
      if parent_in_code
        parent_in_code.namespace_path
      else
        []
      end
    end

    def fully_qualified_name
      namespace_path.map(&:name).join('.')
    end

    attr_accessor :file
    attr_accessor :line
    attr_accessor :column
    attr_accessor :usr
    attr_accessor :name
    attr_accessor :declaration
    attr_accessor :abstract
    attr_accessor :default_impl_abstract
    attr_accessor :from_protocol_extension
    attr_accessor :discussion
    attr_accessor :return
    attr_accessor :parameters
    attr_accessor :url
    attr_accessor :mark
    attr_accessor :access_control_level
    attr_accessor :start_line
    attr_accessor :end_line
    attr_accessor :nav_order

    def overview
      "#{abstract}\n\n#{discussion}".strip
    end
  end
end
