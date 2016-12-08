require 'jazzy/source_declaration/access_control_level'
require 'jazzy/source_declaration/type'

module Jazzy
  class SourceDeclaration
    # kind of declaration (e.g. class, variable, function)
    attr_accessor :type
    # static type of declared element (e.g. String.Type -> ())
    attr_accessor :typename

    def type?(type_kind)
      respond_to?(:type) && type.kind == type_kind
    end

    def render?
      type?('document.markdown') || children.count != 0
    end

    # Element containing this declaration in the code
    attr_accessor :parent_in_code

    # Logical parent in the documentation. May differ from parent_in_code
    # because of top-level categories and merged extensions.
    attr_accessor :parent_in_docs

    # counterpart of parent_in_docs
    attr_accessor :children

    def children=(new_children)
      # Freeze to ensure that parent_in_docs stays in sync
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

    # If this declaration is an objc category, returns an array with the name
    # of the extended objc class and the category name itself, i.e.
    # ["NSString", "MyMethods"], nil otherwise.
    def objc_category_name
      name.split(/[\(\)]/) if type.objc_category?
    end

    attr_accessor :file
    attr_accessor :line
    attr_accessor :column
    attr_accessor :usr
    attr_accessor :modulename
    attr_accessor :name
    attr_accessor :declaration
    attr_accessor :other_language_declaration
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
      "#{alternative_abstract}\n\n#{abstract}\n\n#{discussion}".strip
    end

    def alternative_abstract
      if file = alternative_abstract_file
        Pathname(file).read
      end
    end

    def alternative_abstract_file
      abstract_glob.select do |f|
        File.basename(f).split('.').first == name
      end.first
    end

    def abstract_glob
      return [] unless
        Config.instance.abstract_glob_configured &&
        Config.instance.abstract_glob
      Config.instance.abstract_glob.select { |e| File.file? e }
    end
  end
end
