require 'json'
require 'pathname'
require 'shellwords'
require 'xcinvoke'
require 'cgi'
require 'rexml/document'

require 'jazzy/config'
require 'jazzy/executable'
require 'jazzy/highlighter'
require 'jazzy/source_declaration'
require 'jazzy/source_mark'
require 'jazzy/stats'

ELIDED_AUTOLINK_TOKEN = '36f8f5912051ae747ef441d6511ca4cb'.freeze

def autolink_regex(middle_regex, after_highlight)
  start_tag_re, end_tag_re =
    if after_highlight
      [/<span class="(?:n|kt|kd|nc)">/, '</span>']
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
      link_target = yield(CGI.unescape_html(raw_name))

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

  def unindent(count)
    gsub(/^#{' ' * count}/, '')
  end
end

module Jazzy
  # This module interacts with the sourcekitten command-line executable
  module SourceKitten
    def self.undocumented_abstract
      @undocumented_abstract ||= Markdown.render(
        Config.instance.undocumented_text,
      ).freeze
    end

    # Group root-level docs by custom categories (if any) and type
    def self.group_docs(docs)
      custom_categories, docs = group_custom_categories(docs)
      unlisted_prefix = Config.instance.custom_categories_unlisted_prefix
      type_categories, uncategorized = group_type_categories(
        docs, custom_categories.any? ? unlisted_prefix : ''
      )
      custom_categories + merge_categories(type_categories) + uncategorized
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
          type_category_prefix + type.plural_url_name,
        )
      end
      [group.compact, docs]
    end

    # Join categories with the same name (eg. ObjC and Swift classes)
    def self.merge_categories(categories)
      merged = []
      categories.each do |new_category|
        if existing = merged.find { |c| c.name == new_category.name }
          existing.children += new_category.children
        else
          merged.append(new_category)
        end
      end
      merged
    end

    def self.make_group(group, name, abstract, url_name = nil)
      group.reject! { |doc| doc.name.empty? }
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
    def self.merge_consecutive_marks(docs)
      prev_mark = nil
      docs.each do |doc|
        if prev_mark && prev_mark.can_merge?(doc.mark)
          doc.mark = prev_mark
        end
        prev_mark = doc.mark
        merge_consecutive_marks(doc.children)
      end
    end

    def self.sanitize_filename(doc)
      unsafe_filename = doc.docs_filename
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
        if doc.render_as_page?
          doc.url = (
            subdir_for_doc(doc) +
            [sanitize_filename(doc) + '.html']
          ).map { |path| ERB::Util.url_encode(path) }.join('/')
          doc.children = make_doc_urls(doc.children)
        else
          # Don't create HTML page for this doc if it doesn't have children
          # Instead, make its link a hash-link on its parent's page
          if doc.typename == '<<error type>>'
            warn 'A compile error prevented ' + doc.fully_qualified_name +
                 ' from receiving a unique USR. Documentation may be ' \
                 'incomplete. Please check for compile errors by running ' \
                 '`xcodebuild` or `swift build` with arguments ' \
                 "`#{Config.instance.build_tool_arguments.shelljoin}`."
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

    # Determine the subdirectory in which a doc should be placed.
    # Guides in the root for back-compatibility.
    # Declarations under outer namespace type (Structures, Classes, etc.)
    def self.subdir_for_doc(doc)
      return [] if doc.type.markdown?
      top_level_decl = doc.namespace_path.first
      if top_level_decl.type.name
        [top_level_decl.type.plural_url_name] +
          doc.namespace_ancestors.map(&:name)
      else
        # Category - in the root
        []
      end
    end

    # returns all subdirectories of specified path
    def self.rec_path(path)
      path.children.collect do |child|
        if child.directory?
          rec_path(child) + [child]
        end
      end.select { |x| x }.flatten(1)
    end

    def self.use_spm?(options)
      options.swift_build_tool == :spm ||
        (!options.swift_build_tool_configured &&
         Dir['*.xcodeproj', '*.xcworkspace'].empty? &&
         !options.build_tool_arguments.include?('-project') &&
         !options.build_tool_arguments.include?('-workspace'))
    end

    # Builds SourceKitten arguments based on Jazzy options
    def self.arguments_from_options(options)
      arguments = ['doc']
      if options.objc_mode
        arguments += objc_arguments_from_options(options)
      else
        arguments += ['--spm'] if use_spm?(options)
        unless options.module_name.empty?
          arguments += ['--module-name', options.module_name]
        end
        arguments += ['--']
      end

      arguments + options.build_tool_arguments
    end

    def self.objc_arguments_from_options(options)
      arguments = []
      if options.build_tool_arguments.empty?
        arguments += ['--objc', options.umbrella_header.to_s, '--', '-x',
                      'objective-c', '-isysroot',
                      `xcrun --show-sdk-path --sdk #{options.sdk}`.chomp,
                      '-I', options.framework_root.to_s,
                      '-fmodules']
      end
      # add additional -I arguments for each subdirectory of framework_root
      unless options.framework_root.nil?
        rec_path(Pathname.new(options.framework_root.to_s)).collect do |child|
          if child.directory?
            arguments += ['-I', child.to_s]
          end
        end
      end
      arguments
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
      bin_path = Pathname(__FILE__) + '../../../bin/sourcekitten'
      output, = Executable.execute_command(bin_path, arguments, true, env: env)
      output
    end

    def self.make_default_doc_info(declaration)
      # @todo: Fix these
      declaration.line = nil
      declaration.column = nil
      declaration.abstract = ''
      declaration.parameters = []
      declaration.children = []
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

      type = SourceDeclaration::Type.new(doc['key.kind'])

      # Always document Objective-C declarations.
      return true unless type.swift_type?

      # Don't document Swift types if we are hiding Swift
      return false if Config.instance.hide_swift?

      # Don't document @available declarations with no USR, since it means
      # they're unavailable.
      if availability_attribute?(doc) && !doc['key.usr']
        return false
      end

      # Document enum elements, since we can't tell their ACL.
      return true if type.swift_enum_element?
      # Document extensions if they might have parts covered by the ACL.
      return should_document_swift_extension?(doc) if type.swift_extension?

      acl_ok = SourceDeclaration::AccessControlLevel.from_doc(doc) >= @min_acl
      unless acl_ok
        @stats.add_acl_skipped
        @inaccessible_protocols.append(doc['key.name']) if type.swift_protocol?
      end
      acl_ok
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def self.should_document_swift_extension?(doc)
      doc['key.inheritedtypes'] ||
        Array(doc['key.substructure']).any? do |subdoc|
          subtype = SourceDeclaration::Type.new(subdoc['key.kind'])
          !subtype.mark? && should_document?(subdoc)
        end
    end

    def self.should_mark_undocumented(filepath)
      source_directory = Config.instance.source_directory.to_s
      (filepath || '').start_with?(source_directory)
    end

    def self.process_undocumented_token(doc, declaration)
      make_default_doc_info(declaration)

      filepath = doc['key.filepath']

      if !declaration.swift? || should_mark_undocumented(filepath)
        @stats.add_undocumented(declaration)
        return nil if @skip_undocumented
        declaration.abstract = undocumented_abstract
      else
        declaration.abstract = Markdown.render(doc['key.doc.comment'] || '',
                                               declaration.highlight_language)
      end

      declaration
    end

    def self.parameters(doc, discovered)
      (doc['key.doc.parameters'] || []).map do |p|
        name = p['name']
        {
          name: name,
          discussion: discovered[name],
        }
      end.reject { |param| param[:discussion].nil? }
    end

    def self.make_doc_info(doc, declaration)
      return unless should_document?(doc)

      highlight_declaration(doc, declaration)
      make_deprecation_info(doc, declaration)

      unless doc['key.doc.full_as_xml']
        return process_undocumented_token(doc, declaration)
      end

      declaration.abstract = Markdown.render(doc['key.doc.comment'] || '',
                                             declaration.highlight_language)
      declaration.discussion = ''
      declaration.return = Markdown.rendered_returns
      declaration.parameters = parameters(doc, Markdown.rendered_parameters)

      @stats.add_documented
    end

    def self.highlight_declaration(doc, declaration)
      if declaration.swift?
        declaration.declaration =
          Highlighter.highlight_swift(make_swift_declaration(doc, declaration))
      else
        declaration.declaration =
          Highlighter.highlight_objc(
            make_objc_declaration(doc['key.parsed_declaration']),
          )
        declaration.other_language_declaration =
          Highlighter.highlight_swift(doc['key.swift_declaration'])
      end
    end

    def self.make_deprecation_info(doc, declaration)
      if declaration.deprecated
        declaration.deprecation_message =
          Markdown.render(doc['key.deprecation_message'] || '')
      end
      if declaration.unavailable
        declaration.unavailable_message =
          Markdown.render(doc['key.unavailable_message'] || '')
      end
    end

    # Strip tags and convert entities
    def self.xml_to_text(xml)
      document = REXML::Document.new(xml)
      REXML::XPath.match(document.root, '//text()').map(&:value).join
    rescue
      ''
    end

    # Regexp to match an @attribute.  Complex to handle @available().
    def self.attribute_regexp(name)
      qstring = /"(?:[^"\\]*|\\.)*"/
      %r{@#{name}      # @attr name
        (?:\s*\(       # optionally followed by spaces + parens,
          (?:          # containing any number of either..
            [^")]*|    # normal characters or...
            #{qstring} # quoted strings.
          )*           # (end parens content)
        \))?           # (end optional parens)
      }x
    end

    # Get all attributes of some name
    def self.extract_attributes(declaration, name = '\w+')
      attrs = declaration.scan(attribute_regexp(name))
      # Rouge #806 workaround, use unicode lookalike for ')' inside attributes.
      attrs.map { |str| str.gsub(/\)(?!\s*$)/, "\ufe5a") }
    end

    def self.extract_availability(declaration)
      extract_attributes(declaration, 'available')
    end

    # Split leading attributes from a decl, returning both parts.
    def self.split_decl_attributes(declaration)
      declaration =~ /^((?:#{attribute_regexp('\w+')}\s*)*)(.*)$/m
      Regexp.last_match.captures
    end

    def self.prefer_parsed_decl?(parsed, annotated, type)
      return true if annotated.empty?
      return false unless parsed
      return false if type.swift_variable? # prefer { get }-style

      annotated.include?(' = default') || # SR-2608
        (parsed.scan(/@autoclosure|@escaping/).count >
         annotated.scan(/@autoclosure|@escaping/).count) || # SR-6321
        parsed.include?("\n") # user formatting
    end

    # Apply fixes to improve the compiler's declaration
    def self.fix_up_compiler_decl(annotated_decl, declaration)
      annotated_decl.
        # Replace the fully qualified name of a type with its base name
        gsub(declaration.fully_qualified_name_regexp,
             declaration.name).
        # Workaround for SR-9816
        gsub(" {\n  get\n  }", '').
        # Workaround for SR-12139
        gsub(/mutating\s+mutating/, 'mutating')
    end

    # Find the best Swift declaration
    def self.make_swift_declaration(doc, declaration)
      # From compiler 'quick help' style
      annotated_decl_xml = doc['key.annotated_decl']

      return nil unless annotated_decl_xml

      annotated_decl_attrs, annotated_decl_body =
        split_decl_attributes(xml_to_text(annotated_decl_xml))

      # From source code
      parsed_decl = doc['key.parsed_declaration']

      # Don't present type attributes on extensions
      return parsed_decl if declaration.type.extension?

      decl =
        if prefer_parsed_decl?(parsed_decl,
                               annotated_decl_body,
                               declaration.type)
          # Strip any attrs captured by parsed version
          inline_attrs, parsed_decl_body = split_decl_attributes(parsed_decl)
          parsed_decl_body.unindent(inline_attrs.length)
        else
          # Improve the compiler declaration
          fix_up_compiler_decl(annotated_decl_body, declaration)
        end

      # @available attrs only in compiler 'interface' style
      available_attrs = extract_availability(doc['key.doc.declaration'] || '')

      available_attrs.concat(extract_attributes(annotated_decl_attrs))
                     .push(decl)
                     .join("\n")
    end

    # Strip default property attributes because libclang
    # adds them all, even if absent in the original source code.
    DEFAULT_ATTRIBUTES = %w[atomic readwrite assign unsafe_unretained].freeze

    def self.make_objc_declaration(declaration)
      return declaration if Config.instance.keep_property_attributes

      declaration =~ /\A@property\s+\((.*?)\)/
      return declaration unless Regexp.last_match

      attrs = Regexp.last_match[1].split(',').map(&:strip) - DEFAULT_ATTRIBUTES
      attrs_text = attrs.empty? ? '' : " (#{attrs.join(', ')})"

      declaration.sub(/(?<=@property)\s+\(.*?\)/, attrs_text)
                 .gsub(/\s+/, ' ')
    end

    def self.make_substructure(doc, declaration)
      return [] unless subdocs = doc['key.substructure']
      make_source_declarations(subdocs,
                               declaration,
                               declaration.mark_for_children)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.make_source_declarations(docs, parent = nil, mark = SourceMark.new)
      declarations = []
      current_mark = mark
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
        declaration.objc_name = doc['key.name']
        documented_name = if Config.instance.hide_objc? && doc['key.swift_name']
                            doc['key.swift_name']
                          else
                            declaration.objc_name
                          end
        if declaration.type.task_mark?(documented_name)
          current_mark = SourceMark.new(documented_name)
        end
        if declaration.type.swift_enum_case?
          # Enum "cases" are thin wrappers around enum "elements".
          declarations += make_source_declarations(
            doc['key.substructure'], parent, current_mark
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
        declaration.type_usr = doc['key.typeusr']
        declaration.modulename = doc['key.modulename']
        declaration.name = documented_name
        declaration.mark = current_mark
        declaration.access_control_level =
          SourceDeclaration::AccessControlLevel.from_doc(doc)
        declaration.line = doc['key.doc.line']
        declaration.column = doc['key.doc.column']
        declaration.start_line = doc['key.parsed_scope.start']
        declaration.end_line = doc['key.parsed_scope.end']
        declaration.deprecated = doc['key.always_deprecated']
        declaration.unavailable = doc['key.always_unavailable']
        declaration.generic_requirements =
          find_generic_requirements(doc['key.parsed_declaration'])
        inherited_types = doc['key.inheritedtypes'] || []
        declaration.inherited_types =
          inherited_types.map { |type| type['key.name'] }.compact

        next unless make_doc_info(doc, declaration)
        declaration.children = make_substructure(doc, declaration)
        next if declaration.type.extension? &&
                declaration.children.empty? &&
                !declaration.inherited_types?
        declarations << declaration
      end
      declarations
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def self.find_generic_requirements(parsed_declaration)
      parsed_declaration =~ /\bwhere\s+(.*)$/m
      return nil unless Regexp.last_match
      Regexp.last_match[1].gsub(/\s+/, ' ')
    end

    # Expands extensions of nested types declared at the top level into
    # a tree so they can be deduplicated properly
    def self.expand_extensions(decls)
      decls.map do |decl|
        next decl unless decl.type.extension? && decl.name.include?('.')

        # Don't expand the Swift namespace if we're in ObjC mode.
        # ex: NS_SWIFT_NAME(Foo.Bar) should not create top-level Foo
        next decl if decl.swift_objc_extension? && !Config.instance.hide_objc?

        name_parts = decl.name.split('.')
        decl.name = name_parts.pop
        expand_extension(decl, name_parts, decls)
      end
    end

    def self.expand_extension(extension, name_parts, decls)
      return extension if name_parts.empty?
      name = name_parts.shift
      candidates = decls.select { |decl| decl.name == name }
      SourceDeclaration.new.tap do |decl|
        make_default_doc_info(decl)
        decl.name = name
        decl.modulename = extension.modulename
        decl.type = extension.type
        decl.mark = extension.mark
        decl.usr = candidates.first.usr unless candidates.empty?
        child = expand_extension(extension,
                                 name_parts,
                                 candidates.flat_map(&:children).uniq)
        child.parent_in_code = decl
        decl.children = [child]
      end
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

      duplicate_groups.flat_map do |group|
        # Put extended type (if present) before extensions
        merge_declarations(group)
      end.compact
    end

    # Returns true if an Objective-C declaration is mergeable.
    def self.mergeable_objc?(decl, root_decls)
      decl.type.objc_class? \
        || (decl.type.objc_category? \
            && name_match(decl.objc_category_name[0], root_decls))
    end

    # Returns if a Swift declaration is mergeable.
    # Start off merging in typealiases to help understand extensions.
    def self.mergeable_swift?(decl)
      decl.type.swift_extensible? ||
        decl.type.swift_extension? ||
        decl.type.swift_typealias?
    end

    # Two declarations get merged if they have the same deduplication key.
    def self.deduplication_key(decl, root_decls)
      # Swift extension of objc class
      if decl.swift_objc_extension?
        [decl.swift_extension_objc_name, :objc_class_and_categories]
      # Swift type or Swift extension of Swift type
      elsif mergeable_swift?(decl)
        [decl.usr, decl.name]
      # Objc categories and classes
      elsif mergeable_objc?(decl, root_decls)
        # Using the ObjC name to match swift_objc_extension.
        name, _ = decl.objc_category_name || decl.objc_name
        [name, :objc_class_and_categories]
      # Non-mergable declarations (funcs, typedefs etc...)
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

      extensions = reject_inaccessible_extensions(typedecl, extensions)

      if typedecl
        if typedecl.type.swift_protocol?
          mark_and_merge_protocol_extensions(typedecl, extensions)
          extensions.reject! { |ext| ext.children.empty? }
        end

        merge_objc_declaration_marks(typedecl, extensions)
      end

      # Keep type-aliases separate from any extensions
      if typedecl && typedecl.type.swift_typealias?
        [merge_type_and_extensions(typedecls, []),
         merge_type_and_extensions([], extensions)]
      else
        merge_type_and_extensions(typedecls, extensions)
      end
    end
    # rubocop:enable Metrics/MethodLength

    def self.merge_type_and_extensions(typedecls, extensions)
      # Constrained extensions at the end
      constrained, regular_exts = extensions.partition(&:constrained_extension?)
      decls = typedecls + regular_exts + constrained
      return nil if decls.empty?

      move_merged_extension_marks(decls)
      merge_code_declaration(decls)

      decls.first.tap do |merged|
        merged.children = deduplicate_declarations(
          decls.flat_map(&:children).uniq,
        )
        merged.children.each do |child|
          child.parent_in_code = merged
        end
      end
    end

    # Now we know all the public types and all the private protocols,
    # reject extensions that add public protocols to private types
    # or add private protocols to public types.
    def self.reject_inaccessible_extensions(typedecl, extensions)
      swift_exts, objc_exts = extensions.partition(&:swift?)

      # Reject extensions that are just conformances to private protocols
      unwanted_exts, wanted_exts = swift_exts.partition do |ext|
        ext.children.empty? &&
          !ext.other_inherited_types?(@inaccessible_protocols)
      end

      # Given extensions of a type from this module, without the
      # type itself, the type must be private and the extensions
      # should be rejected.
      if !typedecl &&
         wanted_exts.first &&
         wanted_exts.first.type_from_doc_module?
        unwanted_exts += wanted_exts
        wanted_exts = []
      end

      # Don't tell the user to document them
      unwanted_exts.each { |e| @stats.remove_undocumented(e) }

      objc_exts + wanted_exts
    end

    # Protocol extensions.
    #
    # If any of the extensions provide default implementations for methods in
    # the given protocol, merge those members into the protocol doc instead of
    # keeping them on the extension. These get a “Default implementation”
    # annotation in the generated docs.  Default implementations added by
    # conditional extensions are annotated but listed separately.
    #
    # Protocol methods provided only in an extension and not in the protocol
    # itself are a special beast: they do not use dynamic dispatch. These get an
    # “Extension method” annotation in the generated docs.
    def self.mark_and_merge_protocol_extensions(protocol, extensions)
      extensions.each do |ext|
        ext.children = ext.children.select do |ext_member|
          proto_member = protocol.children.find do |p|
            p.name == ext_member.name && p.type == ext_member.type
          end

          # Extension-only method, keep.
          unless proto_member
            ext_member.from_protocol_extension = true
            next true
          end

          # Default impl but constrained, mark and keep.
          if ext.constrained_extension?
            ext_member.default_impl_abstract = ext_member.abstract
            ext_member.abstract = nil
            next true
          end

          # Default impl for all users, merge.
          proto_member.default_impl_abstract = ext_member.abstract
          next false
        end
      end
    end

    # Mark children merged from categories with the name of category
    # (unless they already have a mark)
    def self.merge_objc_declaration_marks(typedecl, extensions)
      return unless typedecl.type.objc_class?
      extensions.each do |ext|
        _, category_name = ext.objc_category_name
        ext.children.each { |c| c.mark.name ||= category_name }
      end
    end

    # For each extension to be merged, move any MARK from the extension
    # declaration down to the extension contents so it still shows up.
    def self.move_merged_extension_marks(decls)
      return unless to_be_merged = decls[1..-1]
      to_be_merged.each do |ext|
        child = ext.children.first
        if child && child.mark.empty?
          child.mark.copy(ext.mark)
        end
      end
    end

    # Merge useful information added by extensions into the main
    # declaration: public protocol conformances and, for top-level extensions,
    # further conditional extensions of the same type.
    def self.merge_code_declaration(decls)
      first = decls.first

      declarations = decls[1..-1].select do |decl|
        decl.type.swift_extension? &&
          (decl.other_inherited_types?(@inaccessible_protocols) ||
            (first.type.swift_extension? && decl.constrained_extension?))
      end.map(&:declaration)

      unless declarations.empty?
        first.declaration = declarations.prepend(first.declaration).uniq.join
      end
    end

    # Apply filtering based on the "included" and "excluded" flags.
    def self.filter_files(json)
      json = filter_included_files(json) if Config.instance.included_files.any?
      json = filter_excluded_files(json) if Config.instance.excluded_files.any?
      json.map do |doc|
        key = doc.keys.first
        doc[key]
      end.compact
    end

    # Filter based on the "included" flag.
    def self.filter_included_files(json)
      included_files = Config.instance.included_files
      json.map do |doc|
        key = doc.keys.first
        doc if included_files.detect do |include|
          File.fnmatch?(include, key)
        end
      end.compact
    end

    # Filter based on the "excluded" flag.
    def self.filter_excluded_files(json)
      excluded_files = Config.instance.excluded_files
      json.map do |doc|
        key = doc.keys.first
        doc unless excluded_files.detect do |exclude|
          File.fnmatch?(exclude, key)
        end
      end.compact
    end

    def self.name_match(name_part, docs)
      return nil unless name_part
      wildcard_expansion = Regexp.escape(name_part)
                                 .gsub('\.\.\.', '[^)]*')
                                 .gsub(/<.*>/, '')
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
        parts = raw_name.sub(/^@/, '') # ignore for custom attribute ref
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

    AUTOLINK_TEXT_FIELDS = %w[return
                              abstract
                              unavailable_message
                              deprecation_message].freeze

    AUTOLINK_HIGHLIGHT_FIELDS = %w[declaration
                                   other_language_declaration].freeze

    def self.autolink(docs, root_decls)
      @autolink_root_decls = root_decls
      docs.each do |doc|
        doc.children = autolink(doc.children, root_decls)

        AUTOLINK_TEXT_FIELDS.each do |field|
          if text = doc.send(field)
            doc.send(field + '=', autolink_text(text, doc, root_decls))
          end
        end

        AUTOLINK_HIGHLIGHT_FIELDS.each do |field|
          if text = doc.send(field)
            doc.send(field + '=', autolink_text(text, doc, root_decls, true))
          end
        end

        (doc.parameters || []).each do |param|
          param[:discussion] =
            autolink_text(param[:discussion], doc, root_decls)
        end
      end
    end

    # For autolinking external markdown documents
    def self.autolink_document(html, doc)
      autolink_text(html, doc, @autolink_root_decls || [])
    end

    def self.reject_objc_types(docs)
      enums = docs.map do |doc|
        [doc, doc.children]
      end.flatten.select { |child| child.type.objc_enum? }.map(&:objc_name)
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
      @stats = Stats.new
      @inaccessible_protocols = []
      sourcekitten_json = filter_files(JSON.parse(sourcekitten_output).flatten)
      docs = make_source_declarations(sourcekitten_json).concat inject_docs
      docs = expand_extensions(docs)
      docs = deduplicate_declarations(docs)
      docs = reject_objc_types(docs)
      # Remove top-level enum cases because it means they have an ACL lower
      # than min_acl
      docs = docs.reject { |doc| doc.type.swift_enum_element? }
      ungrouped_docs = docs
      docs = group_docs(docs)
      merge_consecutive_marks(docs)
      make_doc_urls(docs)
      autolink(docs, ungrouped_docs)
      [docs, @stats]
    end
  end
end
