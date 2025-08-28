# frozen_string_literal: true

module Jazzy
  # This class stores an index of symbol names for doing name lookup
  # when resolving custom categories and autolinks.
  class DocIndex
    # A node in the index tree.  The root has no decl; its children are
    # per-module indexed by module names.  The second level, where each
    # scope is a module, also has no decl; its children are scopes, one
    # for each top-level decl in the module.  From the third level onwards
    # the decl is valid.
    class Scope
      attr_reader :decl # SourceDeclaration
      attr_reader :children # String:Scope

      def initialize(decl, children)
        @decl = decl
        @children = children
      end

      def self.new_root(module_decls)
        new(nil,
            module_decls.transform_values do |decls|
              Scope.new_decl(nil, decls)
            end)
      end

      # Decl names in a scope are usually unique.  The exceptions
      # are (1) methods and (2) typealias+extension, which historically
      # jazzy does not merge.  The logic here and in `merge()` below
      # preserves the historical ambiguity-resolution of (1) and tries
      # to do the best for (2).
      def self.new_decl(decl, child_decls)
        child_scopes = {}
        child_decls.flat_map do |child_decl|
          child_scope = Scope.new_decl(child_decl, child_decl.children)
          child_decl.index_names.map do |name|
            if curr = child_scopes[name]
              curr.merge(child_scope)
            else
              child_scopes[name] = child_scope
            end
          end
        end
        new(decl, child_scopes)
      end

      def merge(new_scope)
        return unless type = decl&.type
        return unless new_type = new_scope.decl&.type

        if type.swift_typealias? && new_type.swift_extension?
          @children = new_scope.children
        elsif type.swift_extension? && new_type.swift_typealias?
          @decl = new_scope.decl
        end
      end

      # Lookup of a name like `Mod.Type.method(arg:)` requires passing
      # an array of name 'parts' eg. ['Mod', 'Type', 'method(arg:)'].
      def lookup(parts)
        return decl if parts.empty?

        children[parts.first]&.lookup(parts[1...])
      end

      # Look up of a regex matching all children for current level only.
      def lookup_regex(regex)
        pattern = /#{Regexp.quote(regex)}/
        matching_children = children.select { |name, scope| name =~ pattern }
        matching_children.map { |name, scope| scope.decl }.compact
      end

      # Get an array of scopes matching the name parts.
      def lookup_path(parts)
        [self] +
          (children[parts.first]&.lookup_path(parts[1...]) || [])
      end
    end

    attr_reader :root_scope

    def initialize(all_decls)
      @root_scope = Scope.new_root(all_decls.group_by(&:module_name))
    end

    # Look up a name and return the matching SourceDeclaration or nil.
    #
    # `context` is an optional SourceDeclaration indicating where the text
    # was found, affects name resolution - see `lookup_context()` below.
    def lookup(name, context = nil)
      lookup_name = LookupName.new(name)

      return lookup_fully_qualified(lookup_name) if lookup_name.fully_qualified?
      return lookup_guess(lookup_name) if context.nil?

      lookup_context(lookup_name, context)
    end

    # Look up a regex and return all matching top level SourceDeclaration.
    def lookup_regex(regex)
      root_scope.children.map { |name, scope| scope.lookup_regex(regex) }.flatten
    end

    private

    # Look up a fully-qualified name, ie. it starts with the module name.
    def lookup_fully_qualified(lookup_name)
      root_scope.lookup(lookup_name.parts)
    end

    # Look up a top-level name best-effort, searching for a module that
    # has it before trying the first name-part as a module name.
    def lookup_guess(lookup_name)
      root_scope.children.each_value do |module_scope|
        if result = module_scope.lookup(lookup_name.parts)
          return result
        end
      end

      lookup_fully_qualified(lookup_name)
    end

    # Look up a name from a declaration context, approximately how
    # Swift resolves names.
    #
    # 1 - try and resolve with a common prefix, eg. 'B' from 'T.A'
    #     can match 'T.B', or 'R' from 'S.T.A' can match 'S.R'.
    # 2 - try and resolve as a top-level symbol from a different module
    # 3 - (affordance for docs writers) resolve as a child of the context,
    #     eg. 'B' from 'T.A' can match 'T.A.B' *only if* (1,2) fail.
    #     Currently disabled for Swift for back-compatibility.
    def lookup_context(lookup_name, context)
      context_scope_path =
        root_scope.lookup_path(context.fully_qualified_module_name_parts)

      context_scope = context_scope_path.pop
      context_scope_path.reverse.each do |scope|
        if decl = scope.lookup(lookup_name.parts)
          return decl
        end
      end

      lookup_guess(lookup_name) ||
        (lookup_name.objc? && context_scope.lookup(lookup_name.parts))
    end

    # Helper for name lookup, really a cache for information as we
    # try various strategies.
    class LookupName
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def fully_qualified?
        name.start_with?('/')
      end

      def objc?
        name.start_with?('-', '+')
      end

      def parts
        @parts ||= find_parts
      end

      private

      # Turn a name as written into a list of components to
      # be matched.
      # Swift: Strip out odd characters and split
      # ObjC: Compound names look like '+[Class(Category) method:]'
      #       and need to become ['Class(Category)', '+method:']
      def find_parts
        if name =~ /([+-])\[(\w+(?: ?\(\w+\))?) ([\w:]+)\]/
          [Regexp.last_match[2],
           Regexp.last_match[1] + Regexp.last_match[3]]
        else
          name
            .sub(%r{^[@\/]}, '') # ignore custom attribute reference, fully-qualified
            .gsub(/<.*?>/, '') # remove generic parameters
            .split(%r{(?<!\.)[/.](?!\.)}) # dot or slash, but not '...'
            .reject(&:empty?)
        end
      end
    end
  end

  class SourceDeclaration
    # Names for a symbol.  Permits function parameters to be omitted.
    def index_names
      [name, name.sub(/\(.*\)/, '(...)')].uniq
    end
  end
end
