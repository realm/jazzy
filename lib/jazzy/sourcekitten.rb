# frozen_string_literal: true

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
require 'jazzy/grouper'
require 'jazzy/doc_index'

ELIDED_AUTOLINK_TOKEN = '36f8f5912051ae747ef441d6511ca4cb'

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
      link_target, display_name = yield(CGI.unescape_html(raw_name))

      if link_target &&
         !link_target.type.extension? &&
         link_target.url &&
         link_target.url != doc_url.split('#').first && # Don't link to parent
         link_target.url != doc_url # Don't link to self
        "#{start_tag}<a href=\"#{ELIDED_AUTOLINK_TOKEN}#{link_target.url}\">" \
          "#{CGI.escape_html(display_name)}</a>#{end_tag}"
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

    #
    # URL assignment
    #

    def self.sanitize_filename(doc)
      unsafe_filename = doc.docs_filename
      sanitzation_enabled = Config.instance.use_safe_filenames
      if sanitzation_enabled && !doc.type.name_controlled_manually?
        CGI.escape(unsafe_filename).gsub('_', '%5F').tr('%', '_')
      else
        unsafe_filename
      end
    end

    # rubocop:disable Metrics/MethodLength
    # Generate doc URL by prepending its parents' URLs
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
            warn "A compile error prevented #{doc.fully_qualified_name} " \
              'from receiving a unique USR. Documentation may be ' \
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
              'https://github.com/realm/jazzy/issues along with your ' \
              'Xcode project. If this token is declared in an `#if` block, ' \
              'please ignore this message.'
          end
          doc.url = "#{doc.parent_in_docs.url}#/#{id}"
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Determine the subdirectory in which a doc should be placed.
    # Guides in the root for back-compatibility.
    # Declarations under outer namespace type (Structures, Classes, etc.)
    def self.subdir_for_doc(doc)
      if Config.instance.multiple_modules?
        subdir_for_doc_multi_module(doc)
      else
        # Back-compatibility layout version
        subdir_for_doc_single_module(doc)
      end
    end

    # Pre-multi-module site layout, does not allow for
    # types with the same name.
    def self.subdir_for_doc_single_module(doc)
      # Guides + Groups in the root
      return [] if doc.type.markdown? || doc.type.overview?

      [doc.namespace_path.first.type.plural_url_name] +
        doc.namespace_ancestors.map(&:name)
    end

    # Multi-module site layout, separate each module that
    # is being documented.
    def self.subdir_for_doc_multi_module(doc)
      # Guides + Groups in the root
      return [] if doc.type.markdown? || doc.type.overview?

      root_decl = doc.namespace_path.first

      # Extensions need an extra dir to allow for extending
      # ExternalModule1.TypeName and ExternalModule2.TypeName
      namespace_subdir =
        if root_decl.type.swift_extension?
          ['Extensions', root_decl.module_name]
        else
          ['Types']
        end

      [root_decl.doc_module_name] +
        namespace_subdir +
        doc.namespace_ancestors.map(&:name)
    end

    #
    # CLI argument calculation
    #

    # returns all subdirectories of specified path
    def self.rec_path(path)
      path.children.collect do |child|
        if child.directory?
          rec_path(child) + [child]
        end
      end.select { |x| x }.flatten(1)
    end

    def self.use_spm?(module_config)
      module_config.swift_build_tool == :spm ||
        (!module_config.swift_build_tool_configured &&
         Dir['*.xcodeproj', '*.xcworkspace'].empty? &&
         !module_config.build_tool_arguments.include?('-project') &&
         !module_config.build_tool_arguments.include?('-workspace'))
    end

    # Builds SourceKitten arguments based on Jazzy options
    def self.arguments_from_options(module_config)
      arguments = ['doc']
      if module_config.objc_mode
        arguments += objc_arguments_from_options(module_config)
      else
        arguments += ['--spm'] if use_spm?(module_config)
        unless module_config.module_name.empty?
          arguments += ['--module-name', module_config.module_name]
        end
        arguments += ['--']
      end

      arguments + module_config.build_tool_arguments
    end

    def self.objc_arguments_from_options(module_config)
      arguments = []
      if module_config.build_tool_arguments.empty?
        arguments += ['--objc', module_config.umbrella_header.to_s, '--', '-x',
                      'objective-c', '-isysroot',
                      `xcrun --show-sdk-path --sdk #{module_config.sdk}`.chomp,
                      '-I', module_config.framework_root.to_s,
                      '-fmodules']
      end
      # add additional -I arguments for each subdirectory of framework_root
      unless module_config.framework_root.nil?
        rec_path(Pathname.new(module_config.framework_root.to_s)).collect do |child|
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

    #
    # SourceDeclaration generation
    #

    def self.make_default_doc_info(declaration)
      # @todo: Fix these
      declaration.abstract = ''
      declaration.parameters = []
      declaration.children = []
    end

    def self.attribute?(doc, attr_name)
      doc['key.attributes']&.find do |attribute|
        attribute['key.attribute'] == "source.decl.attribute.#{attr_name}"
      end
    end

    def self.availability_attribute?(doc)
      attribute?(doc, 'available')
    end

    def self.spi_attribute?(doc)
      attribute?(doc, '_spi')
    end

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

      # Only document @_spi declarations in some scenarios
      return false unless should_document_spi?(doc)

      # Don't document declarations excluded by the min_acl setting
      if type.swift_extension?
        should_document_swift_extension?(doc)
      else
        should_document_acl?(type, doc)
      end
    end

    # Check visibility: SPI
    def self.should_document_spi?(doc)
      spi_ok = @min_acl < SourceDeclaration::AccessControlLevel.public ||
               Config.instance.include_spi_declarations ||
               (!spi_attribute?(doc) && !doc['key.symgraph_spi'])

      @stats.add_spi_skipped unless spi_ok
      spi_ok
    end

    # Check visibility: access control
    def self.should_document_acl?(type, doc)
      # Include all enum elements for now, can't tell their ACL.
      return true if type.swift_enum_element?

      acl_ok = SourceDeclaration::AccessControlLevel.from_doc(doc) >= @min_acl
      unless acl_ok
        @stats.add_acl_skipped
        @inaccessible_protocols.append(doc['key.name']) if type.swift_protocol?
      end
      acl_ok
    end

    # Document extensions if they add protocol conformances, or have any
    # member that needs to be documented.
    def self.should_document_swift_extension?(doc)
      doc['key.inheritedtypes'] ||
        Array(doc['key.substructure']).any? do |subdoc|
          subtype = SourceDeclaration::Type.new(subdoc['key.kind'])
          !subtype.mark? && should_document?(subdoc)
        end
    end

    def self.process_undocumented_token(doc, declaration)
      make_default_doc_info(declaration)

      if declaration.mark_undocumented?
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
    rescue StandardError
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

    # Keep everything except instructions to us
    def self.extract_documented_attributes(declaration)
      extract_attributes(declaration).reject do |attr|
        attr.start_with?('@_documentation')
      end
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
      extract_availability(doc['key.doc.declaration'] || '')
        .concat(extract_documented_attributes(annotated_decl_attrs))
        .push(decl)
        .join("\n")
    end

    # Exclude non-async routines that accept async closures
    def self.swift_async?(fully_annotated_decl)
      document = REXML::Document.new(fully_annotated_decl)
      !document.elements['/*/syntaxtype.keyword[text()="async"]'].nil?
    rescue StandardError
      nil
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

      declaration
        .sub(/(?<=@property)\s+\(.*?\)/, attrs_text)
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
        declaration.type =
          SourceDeclaration::Type.new(doc['key.kind'],
                                      doc['key.fully_annotated_decl'])
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

        unless documented_name
          warn 'Found a declaration without `key.name` that will be ' \
            'ignored.  Documentation may be incomplete.  This is probably ' \
            'caused by unresolved compiler errors: check the sourcekitten ' \
            'output for error messages.'
          next
        end

        declaration.file = Pathname(doc['key.filepath']) if doc['key.filepath']
        declaration.usr = doc['key.usr']
        declaration.type_usr = doc['key.typeusr']
        declaration.module_name =
          if declaration.swift?
            # Filter out Apple sub-framework implementation names
            doc['key.modulename']&.sub(/\..*$/, '')
          else
            # ObjC best effort, category original module is unavailable
            @current_module_name
          end
        declaration.doc_module_name = @current_module_name
        declaration.name = documented_name
        declaration.mark = current_mark
        declaration.access_control_level =
          SourceDeclaration::AccessControlLevel.from_doc(doc)
        declaration.line = doc['key.doc.line'] || doc['key.line']
        declaration.column = doc['key.doc.column'] || doc['key.column']
        declaration.start_line = doc['key.parsed_scope.start']
        declaration.end_line = doc['key.parsed_scope.end']
        declaration.deprecated = doc['key.always_deprecated']
        declaration.unavailable = doc['key.always_unavailable']
        declaration.generic_requirements =
          find_generic_requirements(doc['key.parsed_declaration'])
        inherited_types = doc['key.inheritedtypes'] || []
        declaration.inherited_types =
          inherited_types.map { |type| type['key.name'] }.compact
        declaration.async =
          doc['key.symgraph_async'] ||
          if xml_declaration = doc['key.fully_annotated_decl']
            swift_async?(xml_declaration)
          end

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

    #
    # SourceDeclaration generation - extension management
    #

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
        decl.module_name = extension.module_name
        decl.doc_module_name = extension.doc_module_name
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
      decl.type.objc_class? ||
        (decl.type.objc_category? &&
          (category_classname = decl.objc_category_name[0]) &&
          root_decls.any? { _1.name == category_classname })
    end

    # Returns if a Swift declaration is mergeable.
    # Start off merging in typealiases to help understand extensions.
    def self.mergeable_swift?(decl)
      decl.type.swift_extensible? ||
        decl.type.swift_extension? ||
        decl.type.swift_typealias?
    end

    # Normally merge all extensions into their types and each other.
    #
    # :none means only merge within a module -- so two extensions to
    #     some type get merged, but an extension to a type from
    #     another documented module does not get merged into that type
    # :extensions means extensions of documented modules get merged,
    #     but if we're documenting ModA and ModB, and they both provide
    #     extensions to Swift.String, then those two extensions still
    #     appear separately.
    #
    # (The USR part of the dedup key means ModA.Foo and ModB.Foo do not
    # get merged.)
    def self.module_deduplication_key(decl)
      if (Config.instance.merge_modules == :none) ||
         (Config.instance.merge_modules == :extensions &&
          decl.extension_of_external_type?)
        decl.doc_module_name
      else
        ''
      end
    end

    # Two declarations get merged if they have the same deduplication key.
    def self.deduplication_key(decl, root_decls)
      mod_key = module_deduplication_key(decl)
      # Swift extension of objc class
      if decl.swift_objc_extension?
        [decl.swift_extension_objc_name, :objc_class_and_categories, mod_key]
      # Swift type or Swift extension of Swift type
      elsif mergeable_swift?(decl)
        [decl.usr, decl.name, mod_key]
      # Objc categories and classes
      elsif mergeable_objc?(decl, root_decls)
        # Using the ObjC name to match swift_objc_extension.
        name, _ = decl.objc_category_name || decl.objc_name
        [name, :objc_class_and_categories, mod_key]
      # Non-mergable declarations (funcs, typedefs etc...)
      else
        [decl.usr, decl.name, decl.type.kind, '']
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # Merges all of the given types and extensions into a single document.
    def self.merge_declarations(decls)
      extensions, typedecls = decls.partition { |d| d.type.extension? }

      if typedecls.size > 1
        info = typedecls
          .map { |t| "#{t.type.name.downcase} #{t.name}" }
          .join(', ')
        warn 'Found conflicting type declarations with the same name, which ' \
          "may indicate a build issue or a bug in Jazzy: #{info}"
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
      if typedecl&.type&.swift_typealias?
        [merge_type_and_extensions(typedecls, []),
         merge_type_and_extensions([], extensions)]
      else
        merge_type_and_extensions(typedecls, extensions)
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
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
            p.name == ext_member.name &&
              p.type == ext_member.type &&
              p.async == ext_member.async
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
      return unless to_be_merged = decls[1..]

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
      declarations = decls[1..].select do |decl|
        decl.type.swift_extension? &&
          (decl.other_inherited_types?(@inaccessible_protocols) ||
            (decls.first.type.swift_extension? && decl.constrained_extension?))
      end.prepend(decls.first)

      html_declaration = ''
      until declarations.empty?
        module_decls, declarations = next_doc_module_group(declarations)
        first = module_decls.first
        if need_doc_module_note?(first, html_declaration)
          html_declaration += "<span class='declaration-note'>From #{first.doc_module_name}:</span>"
        end
        html_declaration += module_decls.map(&:declaration).uniq.join
      end

      # Must preserve `nil` for edge cases
      decls.first.declaration = html_declaration unless html_declaration.empty?
    end

    # Grab all the extensions from the same doc module
    def self.next_doc_module_group(decls)
      decls.partition { _1.doc_module_name == decls.first.doc_module_name }
    end

    # Does this extension/type need a note explaining which doc module it is from?
    # Only for extensions, if there actually are multiple modules.
    # Last condition avoids it for simple 'extension Array'.
    def self.need_doc_module_note?(decl, html_declaration)
      Config.instance.multiple_modules? &&
        decl.type.swift_extension? &&
        !(html_declaration.empty? &&
          !decl.constrained_extension? &&
          !decl.inherited_types?)
    end

    #
    # Autolinking
    #

    # Links recognized top-level declarations within
    # - inlined code within docs
    # - method signatures after they've been processed by the highlighter
    #
    # The `after_highlight` flag is used to differentiate between the two modes.
    #
    # DocC link format - follow Xcode and don't display slash-separated parts.
    def self.autolink_text(text, doc, after_highlight: false)
      text.autolink_block(doc.url, '[^\s]+', after_highlight) do |raw_name|
        sym_name =
          (raw_name[/^<doc:(.*)>$/, 1] || raw_name).sub(/(?<!^)-.+$/, '')

        [@doc_index.lookup(sym_name, doc), sym_name.sub(%r{^.*/}, '')]
      end.autolink_block(doc.url, '[+-]\[\w+(?: ?\(\w+\))? [\w:]+\]',
                         after_highlight) do |raw_name|
        [@doc_index.lookup(raw_name, doc), raw_name]
      end.autolink_block(doc.url, '[+-]\w[\w:]*', after_highlight) do |raw_name|
        [@doc_index.lookup(raw_name, doc), raw_name]
      end
    end

    AUTOLINK_TEXT_FIELDS = %w[return
                              abstract
                              unavailable_message
                              deprecation_message].freeze

    def self.autolink_text_fields(doc)
      AUTOLINK_TEXT_FIELDS.each do |field|
        if text = doc.send(field)
          doc.send(field + '=', autolink_text(text, doc))
        end
      end

      (doc.parameters || []).each do |param|
        param[:discussion] =
          autolink_text(param[:discussion], doc)
      end
    end

    AUTOLINK_HIGHLIGHT_FIELDS = %w[declaration
                                   other_language_declaration].freeze

    def self.autolink_highlight_fields(doc)
      AUTOLINK_HIGHLIGHT_FIELDS.each do |field|
        if text = doc.send(field)
          doc.send(field + '=',
                   autolink_text(text, doc, after_highlight: true))
        end
      end
    end

    def self.autolink(docs)
      docs.each do |doc|
        doc.children = autolink(doc.children)
        autolink_text_fields(doc)
        autolink_highlight_fields(doc)
      end
    end

    # For autolinking external markdown documents
    def self.autolink_document(html, doc)
      autolink_text(html, doc)
    end

    #
    # Entrypoint and misc filtering
    #

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
    def self.parse(sourcekitten_output, options, inject_docs)
      @min_acl = options.min_acl
      @skip_undocumented = options.skip_undocumented
      @stats = Stats.new
      @inaccessible_protocols = []

      # Process each module separately to inject the source module name
      docs = sourcekitten_output.zip(options.module_names).map do |json, name|
        @current_module_name = name
        sourcekitten_dicts = filter_files(JSON.parse(json).flatten)
        make_source_declarations(sourcekitten_dicts)
      end.flatten + inject_docs

      docs = expand_extensions(docs)
      docs = deduplicate_declarations(docs)
      docs = reject_objc_types(docs)
      # Remove top-level enum cases because it means they have an ACL lower
      # than min_acl
      docs = docs.reject { |doc| doc.type.swift_enum_element? }

      @doc_index = DocIndex.new(docs)

      docs = Grouper.group_docs(docs, @doc_index)

      make_doc_urls(docs)
      autolink(docs)
      [docs, @stats]
    end
  end
end
