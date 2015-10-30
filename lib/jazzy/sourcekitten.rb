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

module Jazzy
  # This module interacts with the sourcekitten command-line executable
  module SourceKitten
    @documented_count = 0
    @undocumented_tokens = []

    # Group root-level docs by custom categories (if any) and type
    def self.group_docs(docs)
      custom_categories, docs = group_custom_categories(docs)
      type_categories, uncategorized = group_type_categories(
        docs, custom_categories.any? ? 'Other ' : '')
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
          "The following #{type.plural_name.downcase} are available globally.")
      end
      [group.compact, docs]
    end

    def self.make_group(group, name, abstract)
      SourceDeclaration.new.tap do |sd|
        sd.type     = SourceDeclaration::Type.overview
        sd.name     = name
        sd.abstract = abstract
        sd.children = group
      end unless group.empty?
    end

    # rubocop:disable Metrics/MethodLength
    # Generate doc URL by prepending its parents URLs
    # @return [Hash] input docs with URLs
    def self.make_doc_urls(docs, parents)
      docs.each do |doc|
        if parents.empty? || doc.children.count > 0
          # Create HTML page for this doc if it has children or is root-level
          doc.url = (
            subdir_for_doc(doc, parents) +
            [doc.name + '.html']
          ).join('/')
          doc.children = make_doc_urls(doc.children, parents + [doc])
        else
          # Don't create HTML page for this doc if it doesn't have children
          # Instead, make its link a hash-link on its parent's page
          if doc.typename == '<<error type>>'
            warn 'A compile error prevented ' +
              (parents[1..-1] + [doc]).map(&:name).join('.') +
              ' from receiving a unique USR. Documentation may be ' \
              'incomplete. Please check for compile errors by running ' \
              "`xcodebuild #{Config.instance.xcodebuild_arguments.shelljoin}`."
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
          doc.url = parents.last.url + '#/' + id
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Determine the subdirectory in which a doc should be placed
    def self.subdir_for_doc(doc, parents)
      parents.map(&:name).tap do |names|
        # We always want to create top-level subdirs according to type (Struct,
        # Class, etc), but parents[0] might be a custom category name.
        top_level_decl = (parents + [doc])[1]
        names[0] = top_level_decl.type.plural_name if top_level_decl
      end
    end

    # Builds SourceKitten arguments based on Jazzy options
    def self.arguments_from_options(options)
      arguments = ['doc']
      if options.objc_mode
        if options.xcodebuild_arguments.empty?
          arguments += ['--objc', options.umbrella_header.to_s, '-x',
                        'objective-c', '-isysroot',
                        `xcrun --show-sdk-path`.chomp, '-I',
                        options.framework_root.to_s]
        end
      elsif !options.module_name.empty?
        arguments += ['--module-name', options.module_name]
      end
      arguments + options.xcodebuild_arguments
    end

    # Run sourcekitten with given arguments and return STDOUT
    def self.run_sourcekitten(arguments)
      swift_version = Config.instance.swift_version
      unless xcode = XCInvoke::Xcode.find_swift_version(swift_version)
        raise "Unable to find an Xcode with swift version #{swift_version}."
      end
      bin_path = Pathname(__FILE__).parent + 'SourceKitten/bin/sourcekitten'
      output, _ = Executable.execute_command(bin_path, arguments, true,
                                             env: xcode.as_env)
      output
    end

    def self.make_default_doc_info(declaration)
      # @todo: Fix these
      declaration.line = 0
      declaration.column = 0
      declaration.abstract = 'Undocumented'
      declaration.parameters = []
      declaration.children = []
    end

    def self.documented_child?(doc)
      return false unless doc['key.substructure']
      doc['key.substructure'].any? { |child| documented_child?(child) }
    end

    def self.should_document?(doc)
      return false if doc['key.doc.comment'].to_s.include?(':nodoc:')

      # Always document Objective-C declarations.
      return true if Config.instance.objc_mode

      # Document extensions & enum elements, since we can't tell their ACL.
      type = SourceDeclaration::Type.new(doc['key.kind'])
      return true if type.swift_enum_element?
      if type.extension?
        return Array(doc['key.substructure']).any? do |subdoc|
          should_document?(subdoc)
        end
      end

      SourceDeclaration::AccessControlLevel.from_doc(doc) >= @min_acl
    end

    def self.process_undocumented_token(doc, declaration)
      source_directory = Config.instance.source_directory.to_s
      filepath = doc['key.filepath']
      objc = Config.instance.objc_mode
      if filepath && (filepath.start_with?(source_directory) || objc)
        @undocumented_tokens << doc
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

    def self.make_doc_info(doc, declaration)
      return unless should_document?(doc)
      unless doc['key.doc.full_as_xml']
        return process_undocumented_token(doc, declaration)
      end

      declaration.line = doc['key.doc.line']
      declaration.column = doc['key.doc.column']
      declaration.declaration = Highlighter.highlight(
        doc['key.parsed_declaration'] || doc['key.doc.declaration'],
        Config.instance.objc_mode ? 'objc' : 'swift',
      )
      declaration.abstract = comment_from_doc(doc)
      declaration.discussion = ''
      declaration.return = make_paragraphs(doc, 'key.doc.result_discussion')

      declaration.parameters = parameters(doc)

      @documented_count += 1
    end

    def self.comment_from_doc(doc)
      swift_version = Config.instance.swift_version.to_f
      comment = doc['key.doc.comment'] || ''
      if swift_version < 2
        # comment until first ReST definition
        matches = /^\s*:[^\s]+:/.match(comment)
        comment = comment[0...matches.begin(0)] if matches
      end
      Jazzy.markdown.render(comment)
    end

    def self.make_substructure(doc, declaration)
      if doc['key.substructure']
        declaration.children = make_source_declarations(
          doc['key.substructure'],
        )
      else
        declaration.children = []
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.make_source_declarations(docs)
      declarations = []
      current_mark = SourceMark.new
      Array(docs).each do |doc|
        if doc.key?('key.diagnostic_stage')
          declarations += make_source_declarations(doc['key.substructure'])
          next
        end
        declaration = SourceDeclaration.new
        declaration.type = SourceDeclaration::Type.new(doc['key.kind'])
        declaration.typename = doc['key.typename']
        current_mark = SourceMark.new(doc['key.name']) if declaration.type.mark?
        if declaration.type.swift_enum_case?
          # Enum "cases" are thin wrappers around enum "elements".
          declarations += make_source_declarations(doc['key.substructure'])
          next
        end
        next unless declaration.type.should_document?

        unless declaration.type.name
          raise 'Please file an issue at ' \
                'https://github.com/realm/jazzy/issues about adding support ' \
                "for `#{declaration.type.kind}`."
        end

        declaration.file = Pathname(doc['key.filepath']) if doc['key.filepath']
        declaration.usr  = doc['key.usr']
        declaration.name = doc['key.name']
        declaration.mark = current_mark
        declaration.access_control_level =
          SourceDeclaration::AccessControlLevel.from_doc(doc)
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
      return 0 if @documented_count == 0 && @undocumented_tokens.count == 0
      (100 * @documented_count) /
        (@undocumented_tokens.count + @documented_count)
    end

    # Merges multiple extensions of the same entity into a single document.
    #
    # Merges extensions into the protocol/class/struct/enum they extend, if it
    # occurs in the same project.
    #
    # Merges redundant declarations when documenting podspecs.
    def self.deduplicate_declarations(declarations)
      duplicate_groups = declarations.group_by { |d| deduplication_key(d) }.values

      duplicate_groups.map do |group|
        # Put extended type (if present) before extensions
        merge_declarations(group)
      end
    end

    # Two declarations get merged if they have the same deduplication key.
    def self.deduplication_key(decl)
      if decl.type.extensible? || decl.type.extension?
        [decl.usr]
      else
        [decl.usr, decl.type.kind]
      end
    end

    # Merges all of the given types and extensions into a single document.
    def self.merge_declarations(decls)
      extensions, typedecls = decls.partition { |d| d.type.extension? }

      if typedecls.size > 1
        warn "Found conflicting type declarations with the same name, which " +
          "may indicate a build issue or a bug in Jazzy: " +
          typedecls.map { |t| "#{t.type.name.downcase} #{t.name}" }.join(', ')
      end
      typedecl = typedecls.first

      if typedecl && typedecl.type.protocol?
        merge_default_implementations_into_protocol(typedecl, extensions)
        extensions.reject! { |ext| ext.children.empty? }

        extensions.each do |ext|
          ext.children.each do |ext_member|
            ext_member.merged_from_protocol_extension = true
          end
        end
      end

      decls = typedecls + extensions
      decls.first.tap do |d|
        d.children = deduplicate_declarations(decls.flat_map(&:children).uniq)
      end
    end

    # If any of the extensions provide default implementations for methods in the
    # given protocol, merge those members into the protocol doc instead of keeping
    # them on the extension.
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

    def self.filter_excluded_files(json)
      excluded_files = Config.instance.excluded_files
      json.map do |doc|
        key = doc.keys.first
        doc[key] unless excluded_files.include?(key)
      end.compact
    end

    def self.names_and_urls(docs)
      docs.flat_map do |doc|
        # FIXME: autolink more than just top-level items.
        [{ name: doc.name, url: doc.url }] # + names_and_urls(doc.children)
      end
    end

    def self.autolink_text(text, data, url)
      regex = /\b(#{data.map { |d| Regexp.escape(d[:name]) }.join('|')})\b/
      text.gsub(regex) do
        name = Regexp.last_match(1)
        auto_url = data.find { |d| d[:name] == name }[:url]
        if auto_url == url # docs shouldn't autolink to themselves
          Regexp.last_match(0)
        else
          "<a href=\"#{ELIDED_AUTOLINK_TOKEN}#{auto_url}\">#{name}</a>"
        end
      end
    end

    def self.autolink(docs, data)
      docs.map do |doc|
        doc.abstract = autolink_text(doc.abstract, data, doc.url)
        doc.return = autolink_text(doc.return, data, doc.url) if doc.return
        doc.children = autolink(doc.children, data)
        doc
      end
    end

    def self.reject_objc_enum_typedefs(docs)
      enums = docs.flat_map do |doc|
        doc.children.select { |child| child.type.objc_enum? }.map(&:name)
      end
      docs.map do |doc|
        doc.children.reject! do |child|
          child.type.objc_typedef? && enums.include?(child.name)
        end
        doc
      end
    end

    # Parse sourcekitten STDOUT output as JSON
    # @return [Hash] structured docs
    def self.parse(sourcekitten_output, min_acl, skip_undocumented)
      @min_acl = min_acl
      @skip_undocumented = skip_undocumented
      sourcekitten_json = filter_excluded_files(JSON.parse(sourcekitten_output))
      docs = make_source_declarations(sourcekitten_json)
      docs = deduplicate_declarations(docs)
      docs = group_docs(docs)
      if Config.instance.objc_mode
        docs = reject_objc_enum_typedefs(docs)
      else
        # Remove top-level enum cases because it means they have an ACL lower
        # than min_acl
        docs = docs.reject { |doc| doc.type.swift_enum_element? }
      end
      docs = make_doc_urls(docs, [])
      docs = autolink(docs, names_and_urls(docs.flat_map(&:children)))
      [docs, doc_coverage, @undocumented_tokens]
    end
  end
end
