# frozen_string_literal: true

module Jazzy
  # This module deals with arranging top-level declarations and guides into
  # groups automatically and/or using a custom list.
  module Grouper
    extend Config::Mixin

    # Group root-level docs by custom categories (if any) and type or module
    def self.group_docs(docs, doc_index)
      custom_categories, docs = group_custom_categories(docs, doc_index)
      unlisted_prefix = config.custom_categories_unlisted_prefix
      type_category_prefix = custom_categories.any? ? unlisted_prefix : ''
      all_categories =
        custom_categories +
        if config.merge_modules == :all
          group_docs_by_type(docs, type_category_prefix)
        else
          group_docs_by_module(docs, type_category_prefix)
        end
      merge_consecutive_marks(all_categories)
    end

    # Group root-level docs by type
    def self.group_docs_by_type(docs, type_category_prefix)
      type_groups = SourceDeclaration::Type.all.map do |type|
        children, docs = docs.partition { |doc| doc.type == type }
        make_type_group(children, type, type_category_prefix)
      end
      merge_categories(type_groups.compact) + docs
    end

    # Group root-level docs by module name
    def self.group_docs_by_module(docs, type_category_prefix)
      guide_categories, docs = group_guides(docs, type_category_prefix)

      module_categories = docs
        .group_by(&:doc_module_name)
        .map do |name, module_docs|
          make_group(
            module_docs,
            name,
            "The following declarations are provided by module #{name}.",
          )
        end

      guide_categories + module_categories
    end

    def self.group_custom_categories(docs, doc_index)
      group = config.custom_categories.map do |category|
        children = category['children'].map do |name|
          unless doc = doc_index.lookup(name)
            warn 'WARNING: No documented top-level declarations match ' \
              "name \"#{name}\" specified in categories file"
            next nil
          end

          unless doc.parent_in_code.nil?
            warn "WARNING: Declaration \"#{doc.fully_qualified_module_name}\" " \
              'specified in categories file exists but is not top-level and ' \
              'cannot be included here'
            next nil
          end

          docs.delete(doc)
        end.compact
        # Category config overrides alphabetization
        children.each.with_index { |child, i| child.nav_order = i }
        make_group(children, category['name'], '')
      end

      globals_grouped_by_file = self.group_globals_by_file(docs, doc_index)
      [group.compact, docs + globals_grouped_by_file]
    end

    def self.group_globals_by_file(docs, doc_index)
      types_to_files_to_symbols = {}
      doc_index.each do |index_item|
        if index_item.parent_in_code.nil? && (index_item.type.name == "Constant" || index_item.type.name == "Function")
          file_name = File.basename(index_item.file, ".*")
          types_to_files_to_symbols[index_item.type.plural_name] ||= {}
          types_to_files_to_symbols[index_item.type.plural_name][file_name] ||= []

          types_to_files_to_symbols[index_item.type.plural_name][file_name] << docs.delete(index_item)

        end
      end

      types_to_file_groups = {}
      types_to_files_to_symbols.each do |type_name, files|
        types_to_file_groups[type_name] ||= []
        files.each do |file, declarations|
          file_group = make_group(declarations, file, 'Globally available these types, are.')
          file_group.url_name = "#{file}+#{type_name}"
          types_to_file_groups[type_name] << file_group
        end
      end

      type_groups = types_to_file_groups.map do |type_name, files_level_declarations|
        make_group(files_level_declarations, type_name, 'These types are available globally.')
      end.compact
      
      type_groups
    end

    def self.group_guides(docs, prefix)
      guides, others = docs.partition { |doc| doc.type.markdown? }
      return [[], others] unless guides.any?

      [[make_type_group(guides, guides.first.type, prefix)], others]
    end

    def self.make_type_group(docs, type, type_category_prefix)
      make_group(
        docs,
        type_category_prefix + type.plural_name,
        "The following #{type.plural_name.downcase} are available globally.",
        type_category_prefix + type.plural_url_name,
      )
    end

    # Join categories with the same name (eg. ObjC and Swift classes)
    def self.merge_categories(categories)
      merged = []
      categories.each do |new_category|
        if existing = merged.find { |cat| cat.name == new_category.name }
          existing.children += new_category.children
        else
          merged.append(new_category)
        end
      end
      merged
    end

    def self.make_group(group, name, abstract, url_name = nil)
      group.reject! { |decl| decl.name.empty? }
      unless group.empty?
        SourceDeclaration.new.tap do |sd|
          sd.type     = SourceDeclaration::Type.overview
          sd.name     = name
          sd.url_name = url_name
          sd.abstract = Markdown.render(abstract)
          sd.children = group
        end
      end
    end

    # Merge consecutive sections with the same mark into one section
    # Needed because of pulling various decls into groups
    def self.merge_consecutive_marks(docs)
      prev_mark = nil
      docs.each do |doc|
        if prev_mark&.can_merge?(doc.mark)
          doc.mark = prev_mark
        end
        prev_mark = doc.mark
        merge_consecutive_marks(doc.children)
      end
    end
  end
end
