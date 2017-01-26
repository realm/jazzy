require 'json'
require 'pathname'
require 'shellwords'
require 'xcinvoke'

require 'jazzy/config'
require 'jazzy/executable'
require 'jazzy/highlighter'
require 'jazzy/source_declaration'
require 'jazzy/source_mark'

ELIDED_AUTOLINK_TOKEN = '36f8f5912051ae747ef441d6511ca4cb'.freeze

def autolink_regex(middle_regex, after_highlight)
  start_tag_re, end_tag_re =
    if after_highlight
      [/<span class="(?:n|kt|nc)">/, '</span>']
    else
      ['<code>', '</code>']
    end
  /(#{start_tag_re})[ \t]*(#{middle_regex})[ \t]*(#{end_tag_re})/
end

class String
  def autolink_block(doc_url, middle_regex, after_highlight)
    gsub(autolink_regex(middle_regex, after_highlight)) do
      original = Regexp.last_match(0)
      start_tag, raw_name, end_tag = Regexp.last_match.captures
      link_target = yield(raw_name)

      if link_target &&
         !link_target.type.extension? &&
         link_target.url &&
         link_target.url != doc_url.split('#').first && # Don't link to parent
         link_target.url != doc_url # Don't link to self
        start_tag +
          "<a href=\"#{ELIDED_AUTOLINK_TOKEN}#{link_target.url}\">" +
          raw_name + '</a>' + end_tag
      else
        original
      end
    end
  end
end

module Jazzy
  # This module interacts with the sourcekitten command-line executable
  module SourceKitten
    @documented_count = 0
    @undocumented_decls = []

    # Group root-level docs by custom categories (if any) and type
    def self.group_docs(docs)
      custom_categories, docs = group_custom_categories(docs)
      type_categories, uncategorized = group_type_categories(
        docs, custom_categories.any? ? 'Other ' : ''
      )
      custom_categories + type_categories + uncategorized
    end

    def self.group_custom_categories(docs)
      group = Config.instance.custom_categories.map do |category|
        children = category['children'].flat_map do |name|
          docs_with_name, docs = docs.partition { |doc| doc.name == name }
          if docs_with_name.empty?
            STDERR.puts 'WARNING: No documented top-level declarations match ' \
                        "name \"#{name}\" specified in categories file"
          end
          docs_with_name
        end
        # Category config overrides alphabetization
        children.each.with_index { |child, i| child.nav_order = i }
        make_group(children, category['name'], '')
      end
      [group.compact, docs]
    end

    def self.group_type_categories(docs, type_category_prefix)
      group = SourceDeclaration::Type.all.map do |type|
        children, docs = docs.partition { |doc| doc.type == type }
        make_group(
          children,
          type_category_prefix + type.plural_name,
          "The following #{type.plural_name.downcase} are available globally.",
        )
      end
      [group.compact, docs]
    end

    def self.make_group(group, name, abstract)
      group.reject! { |doc| doc.name.empty? }
      unless group.empty?
        SourceDeclaration.new.tap do |sd|
          sd.type     = SourceDeclaration::Type.overview
          sd.name     = name
          sd.abstract = abstract
          sd.children = group
        end
      end
    end

    def self.sanitize_filename(doc)
      unsafe_filename = doc.name
      sanitzation_enabled = Config.instance.use_safe_filenames
      if sanitzation_enabled && !doc.type.name_controlled_manually?
        return CGI.escape(unsafe_filename).gsub('_', '%5F').tr('%', '_')
      else
        return unsafe_filename
      end
    end

    # rubocop:disable Metrics/MethodLength
    # Generate doc URL by prepending its parents URLs
    # @return [Hash] input docs with URLs
    def self.make_doc_urls(docs)
      docs.each do |doc|
        if !doc.parent_in_docs || doc.children.count > 0
          # Create HTML page for this doc if it has children or is root-level
          doc.url = (
            subdir_for_doc(doc) +
            [sanitize_filename(doc) + '.html']
          ).join('/')
          doc.children = make_doc_urls(doc.children)
        else
          # Don't create HTML page for this doc if it doesn't have children
          # Instead, make its link a hash-link on its parent's page
          if doc.typename == '<<error type>>'
            warn 'A compile error prevented ' + doc.fully_qualified_name +
                 ' from receiving a unique USR. Documentation may be ' \
                 'incomplete. Please check for compile errors by running ' \
                 '`xcodebuild ' \
                 "#{Config.instance.xcodebuild_arguments.shelljoin}`."
          end
          id = doc.usr
          unless id
            id = doc.name || 'unknown'
            warn "`#{id}` has no USR. First make sure all modules used in " \
              'your project have been imported. If all used modules are ' \
              'imported, please report this problem by filing an issue at ' \
              'https://github.com/realm/jazzy/issues along with your Xcode ' \
              'project. If this token is declared in an `#if` block, please ' \
              'ignore this message.'
          end
          doc.url = doc.parent_in_docs.url + '#/' + id
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Determine the subdirectory in which a doc should be placed
    def self.subdir_for_doc(doc)
      # We always want to create top-level subdirs according to type (Struct,
      # Class, etc).
      top_level_decl = doc.namespace_path.first
      if top_level_decl && top_level_decl.type && top_level_decl.type.name
        # File program elements under top ancestor’s type (Struct, Class, etc.)
        [top_level_decl.type.plural_name] + doc.namespace_ancestors.map(&:name)
      else
        # Categories live in their own directory
        []
      end
    end

    # Builds SourceKitten arguments based on Jazzy options
    def self.arguments_from_options(options)
      arguments = ['doc']
      if options.objc_mode
        if options.xcodebuild_arguments.empty?
          arguments += ['--objc', options.umbrella_header.to_s, '--', '-x',
                        'objective-c', '-isysroot',
                        `xcrun --show-sdk-path --sdk #{options.sdk}`.chomp,
                        '-I', options.framework_root.to_s]
        end
      elsif !options.module_name.empty?
        arguments += ['--module-name', options.module_name, '--']
      else
        arguments += ['--']
      end
      arguments + options.xcodebuild_arguments
    end

    # Run sourcekitten with given arguments and return STDOUT
    def self.run_sourcekitten(arguments)
      if swift_version = Config.instance.swift_version
        unless xcode = XCInvoke::Xcode.find_swift_version(swift_version)
          raise "Unable to find an Xcode with swift version #{swift_version}."
        end
        env = xcode.as_env
      else
        env = ENV
      end
      bin_path = Pathname(__FILE__).parent + 'SourceKitten/bin/sourcekitten'
      output, = Executable.execute_command(bin_path, arguments, true, env: env)
      output
    end

    def self.make_default_doc_info(declaration)
      # @todo: Fix these
      declaration.line = nil
      declaration.column = nil
      declaration.abstract = 'Undocumented'
      declaration.parameters = []
      declaration.children = []
    end

    def self.documented_child?(doc)
      return false unless doc['key.substructure']
      doc['key.substructure'].any? { |child| documented_child?(child) }
    end

    def self.availability_attribute?(doc)
      return false unless doc['key.attributes']
      !doc['key.attributes'].select do |attribute|
        attribute.values.first == 'source.decl.attribute.available'
      end.empty?
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.should_document?(doc)
      return false if doc['key.doc.comment'].to_s.include?(':nodoc:')

      # Always document Objective-C declarations.
      return true if Config.instance.objc_mode

      # Don't document @available declarations with no USR, since it means
      # they're unavailable.
      if availability_attribute?(doc) && !doc['key.usr']
        return false
      end

      # Document extensions & enum elements, since we can't tell their ACL.
      type = SourceDeclaration::Type.new(doc['key.kind'])
      return true if type.swift_enum_element?
      if type.swift_extension?
        return Array(doc['key.substructure']).any? do |subdoc|
          subtype = SourceDeclaration::Type.new(subdoc['key.kind'])
          !subtype.mark? && should_document?(subdoc)
        end
      end

      SourceDeclaration::AccessControlLevel.from_doc(doc) >= @min_acl
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def self.should_mark_undocumented(kind, filepath)
      source_directory = Config.instance.source_directory.to_s
      (filepath || '').start_with?(source_directory) &&
        kind != 'source.lang.swift.decl.generic_type_param'
    end

    def self.process_undocumented_token(doc, declaration)
      filepath = doc['key.filepath']
      objc = Config.instance.objc_mode
      if objc || should_mark_undocumented(doc['key.kind'], filepath)
        @undocumented_decls << declaration
      end
      return nil if !documented_child?(doc) && @skip_undocumented
      make_default_doc_info(declaration)
    end

    def self.make_paragraphs(doc, key)
      return nil unless doc[key]
      doc[key].map do |p|
        if para = p['Para']
          Jazzy.markdown.render(para)
        elsif code = p['Verbatim'] || p['CodeListing']
          Jazzy.markdown.render("```\n#{code}```\n")
        else
          warn "Jazzy could not recognize the `#{p.keys.first}` tag. " \
               'Please report this by filing an issue at ' \
               'https://github.com/realm/jazzy/issues along with the comment ' \
               'including this tag.'
          Jazzy.markdown.render(p.values.first)
        end
      end.join
    end

    def self.parameters(doc)
      (doc['key.doc.parameters'] || []).map do |p|
        {
          name: p['name'],
          discussion: make_paragraphs(p, 'discussion'),
        }
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.make_doc_info(doc, declaration)
      return unless should_document?(doc)

      unless doc['key.doc.full_as_xml']
        return process_undocumented_token(doc, declaration)
      end

      declaration.declaration = Highlighter.highlight(
        doc['key.parsed_declaration'] || doc['key.doc.declaration'],
        Config.instance.objc_mode ? 'objc' : 'swift',
      )
      if Config.instance.objc_mode && doc['key.swift_declaration']
        declaration.other_language_declaration = Highlighter.highlight(
          doc['key.swift_declaration'], 'swift'
        )
      end

      declaration.abstract = Jazzy.markdown.render(doc['key.doc.comment'] || '')
      declaration.discussion = ''
      declaration.return = make_paragraphs(doc, 'key.doc.result_discussion')

      declaration.parameters = parameters(doc)

      @documented_count += 1
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def self.make_substructure(doc, declaration)
      declaration.children = if doc['key.substructure']
                               make_source_declarations(
                                 doc['key.substructure'],
                                 declaration,
                               )
                             else
                               []
                             end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.make_source_declarations(docs, parent = nil)
      declarations = []
      current_mark = SourceMark.new
      Array(docs).each do |doc|
        if doc.key?('key.diagnostic_stage')
          declarations += make_source_declarations(
            doc['key.substructure'], parent
          )
          next
        end
        declaration = SourceDeclaration.new
        declaration.parent_in_code = parent
        declaration.type = SourceDeclaration::Type.new(doc['key.kind'])
        declaration.typename = doc['key.typename']
        current_mark = SourceMark.new(doc['key.name']) if declaration.type.mark?
        if declaration.type.swift_enum_case?
          # Enum "cases" are thin wrappers around enum "elements".
          declarations += make_source_declarations(
            doc['key.substructure'], parent
          )
          next
        end
        next unless declaration.type.should_document?

        unless declaration.type.name
          raise 'Please file an issue at ' \
                'https://github.com/realm/jazzy/issues about adding support ' \
                "for `#{declaration.type.kind}`."
        end

        declaration.file = Pathname(doc['key.filepath']) if doc['key.filepath']
        declaration.usr = doc['key.usr']
        declaration.modulename = doc['key.modulename']
        declaration.name = doc['key.name']
        declaration.mark = current_mark
        declaration.access_control_level =
          SourceDeclaration::AccessControlLevel.from_doc(doc)
        declaration.line = doc['key.doc.line']
        declaration.column = doc['key.doc.column']
        declaration.start_line = doc['key.parsed_scope.start']
        declaration.end_line = doc['key.parsed_scope.end']

        next unless make_doc_info(doc, declaration)
        make_substructure(doc, declaration)
        declarations << declaration
      end
      declarations
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def self.doc_coverage
      return 0 if @documented_count == 0 && @undocumented_decls.count == 0
      (100 * @documented_count) /
        (@undocumented_decls.count + @documented_count)
    end

    # Merges multiple extensions of the same entity into a single document.
    #
    # Merges extensions into the protocol/class/struct/enum they extend, if it
    # occurs in the same project.
    #
    # Merges redundant declarations when documenting podspecs.
    def self.deduplicate_declarations(declarations)
      duplicate_groups = declarations
                         .group_by { |d| deduplication_key(d, declarations) }
                         .values

      duplicate_groups.map do |group|
        # Put extended type (if present) before extensions
        merge_declarations(group)
      end
    end

    # Returns true if an Objective-C declaration is mergeable.
    def self.mergeable_objc?(decl, root_decls)
      decl.type.objc_class? \
        || (decl.type.objc_category? \
            && name_match(decl.objc_category_name[0], root_decls))
    end

    # Two declarations get merged if they have the same deduplication key.
    def self.deduplication_key(decl, root_decls)
      if decl.type.swift_extensible? || decl.type.swift_extension?
        [decl.usr, decl.name]
      elsif mergeable_objc?(decl, root_decls)
        name, _ = decl.objc_category_name || decl.name
        [name, :objc_class_and_categories]
      else
        [decl.usr, decl.name, decl.type.kind]
      end
    end

    # rubocop:disable Metrics/MethodLength
    # Merges all of the given types and extensions into a single document.
    def self.merge_declarations(decls)
      extensions, typedecls = decls.partition { |d| d.type.extension? }

      if typedecls.size > 1
        warn 'Found conflicting type declarations with the same name, which ' \
          'may indicate a build issue or a bug in Jazzy: ' +
             typedecls.map { |t| "#{t.type.name.downcase} #{t.name}" }
             .join(', ')
      end
      typedecl = typedecls.first

      if typedecl && typedecl.type.swift_protocol?
        merge_default_implementations_into_protocol(typedecl, extensions)
        mark_members_from_protocol_extension(extensions)
        extensions.reject! { |ext| ext.children.empty? }
      elsif typedecl && typedecl.type.objc_class?
        # Mark children merged from categories with the name of category
        # (unless they already have a mark)
        extensions.each do |ext|
          _, category_name = ext.objc_category_name
          ext.children.each { |c| c.mark.name ||= category_name }
        end
      end

      decls = typedecls + extensions
      decls.first.tap do |merged|
        merged.children = deduplicate_declarations(
          decls.flat_map(&:children).uniq,
        )
        merged.children.each do |child|
          child.parent_in_code = merged
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # If any of the extensions provide default implementations for methods in
    # the given protocol, merge those members into the protocol doc instead of
    # keeping them on the extension. These get a “Default implementation”
    # annotation in the generated docs.
    def self.merge_default_implementations_into_protocol(protocol, extensions)
      protocol.children.each do |proto_method|
        extensions.each do |ext|
          defaults, ext.children = ext.children.partition do |ext_member|
            ext_member.name == proto_method.name
          end
          unless defaults.empty?
            proto_method.default_impl_abstract =
              defaults.flat_map { |d| [d.abstract, d.discussion] }.join("\n\n")
          end
        end
      end
    end

    # Protocol methods provided only in an extension and not in the protocol
    # itself are a special beast: they do not use dynamic dispatch. These get an
    # “Extension method” annotation in the generated docs.
    def self.mark_members_from_protocol_extension(extensions)
      extensions.each do |ext|
        ext.children.each do |ext_member|
          ext_member.from_protocol_extension = true
        end
      end
    end

    def self.filter_excluded_files(json)
      excluded_files = Config.instance.excluded_files
      json.map do |doc|
        key = doc.keys.first
        doc[key] unless excluded_files.detect do |exclude|
          File.fnmatch?(exclude, key)
        end
      end.compact
    end

    def self.name_match(name_part, docs)
      return nil unless name_part
      wildcard_expansion = Regexp.escape(name_part)
                                 .gsub('\.\.\.', '[^)]*')
                                 .gsub(/&lt;.*&gt;/, '')
      whole_name_pat = /\A#{wildcard_expansion}\Z/
      docs.find do |doc|
        whole_name_pat =~ doc.name
      end
    end

    # Find the first ancestor of doc whose name matches name_part.
    def self.ancestor_name_match(name_part, doc)
      doc.namespace_ancestors.reverse_each do |ancestor|
        if match = name_match(name_part, ancestor.children)
          return match
        end
      end
      nil
    end

    def self.name_traversal(name_parts, doc)
      while doc && !name_parts.empty?
        next_part = name_parts.shift
        doc = name_match(next_part, doc.children)
      end
      doc
    end

    # Links recognized top-level declarations within
    # - inlined code within docs
    # - method signatures after they've been processed by the highlighter
    #
    # The `after_highlight` flag is used to differentiate between the two modes.
    def self.autolink_text(text, doc, root_decls, after_highlight = false)
      text.autolink_block(doc.url, '[^\s]+', after_highlight) do |raw_name|
        parts = raw_name
                .split(/(?<!\.)\.(?!\.)/) # dot with no neighboring dots
                .reject(&:empty?)

        # First dot-separated component can match any ancestor or top-level doc
        first_part = parts.shift
        name_root = ancestor_name_match(first_part, doc) ||
                    name_match(first_part, root_decls)

        # Traverse children via subsequence components, if any
        name_traversal(parts, name_root)
      end.autolink_block(doc.url, '[+-]\[\w+(?: ?\(\w+\))? [\w:]+\]',
                         after_highlight) do |raw_name|
        match = raw_name.match(/([+-])\[(\w+(?: ?\(\w+\))?) ([\w:]+)\]/)

        # Subject component can match any ancestor or top-level doc
        subject = match[2].delete(' ')
        name_root = ancestor_name_match(subject, doc) ||
                    name_match(subject, root_decls)

        if name_root
          # Look up the verb in the subject’s children
          name_match(match[1] + match[3], name_root.children)
        end
      end.autolink_block(doc.url, '[+-]\w[\w:]*', after_highlight) do |raw_name|
        name_match(raw_name, doc.children)
      end
    end

    def self.autolink(docs, root_decls)
      docs.each do |doc|
        doc.children = autolink(doc.children, root_decls)

        doc.return = autolink_text(doc.return, doc, root_decls) if doc.return
        doc.abstract = autolink_text(doc.abstract, doc, root_decls)

        if doc.declaration
          doc.declaration = autolink_text(
            doc.declaration, doc, root_decls, true
          )
        end

        if doc.other_language_declaration
          doc.other_language_declaration = autolink_text(
            doc.other_language_declaration, doc, root_decls, true
          )
        end
      end
    end

    def self.reject_objc_types(docs)
      enums = docs.map do |doc|
        [doc, doc.children]
      end.flatten.select { |child| child.type.objc_enum? }.map(&:name)
      docs.map do |doc|
        doc.children = doc.children.reject do |child|
          child.type.objc_typedef? && enums.include?(child.name)
        end
        doc
      end.reject do |doc|
        doc.type.objc_unexposed? ||
          (doc.type.objc_typedef? && enums.include?(doc.name))
      end
    end

    # Parse sourcekitten STDOUT output as JSON
    # @return [Hash] structured docs
    def self.parse(sourcekitten_output, min_acl, skip_undocumented, inject_docs)
      @min_acl = min_acl
      @skip_undocumented = skip_undocumented
      sourcekitten_json = filter_excluded_files(JSON.parse(sourcekitten_output))
      docs = make_source_declarations(sourcekitten_json).concat inject_docs
      docs = deduplicate_declarations(docs)
      if Config.instance.objc_mode
        docs = reject_objc_types(docs)
      else
        # Remove top-level enum cases because it means they have an ACL lower
        # than min_acl
        docs = docs.reject { |doc| doc.type.swift_enum_element? }
      end
      ungrouped_docs = docs
      docs = group_docs(docs)
      make_doc_urls(docs)
      autolink(docs, ungrouped_docs)
      [docs, doc_coverage, @undocumented_decls]
    end
  end
end
