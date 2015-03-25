require 'json'
require 'pathname'

require 'jazzy/config'
require 'jazzy/source_declaration'
require 'jazzy/source_mark'
require 'jazzy/xml_helper'
require 'jazzy/highlighter'

module Jazzy
  # This module interacts with the sourcekitten command-line executable
  module SourceKitten
    @documented_count = 0
    @undocumented_tokens = []

    # Group root-level docs by type and add as children to a group doc element
    def self.group_docs(docs, type)
      group, docs = docs.partition { |doc| doc.type == type }
      docs << SourceDeclaration.new.tap do |sd|
        sd.type     = SourceDeclaration::Type.overview
        sd.name     = type.plural_name
        sd.abstract = "The following #{type.plural_name.downcase} are " \
                      'available globally.'
        sd.children = group
      end if group.count > 0
      docs
    end

    # Generate doc URL by prepending its parents URLs
    # @return [Hash] input docs with URLs
    def self.make_doc_urls(docs, parents)
      docs.each do |doc|
        if doc.children.count > 0
          # Create HTML page for this doc if it has children
          parents_slash = parents.count > 0 ? '/' : ''
          doc.url = parents.join('/') + parents_slash + doc.name + '.html'
          doc.children = make_doc_urls(doc.children, parents + [doc.name])
        else
          # Don't create HTML page for this doc if it doesn't have children
          # Instead, make its link a hash-link on its parent's page
          id = doc.usr
          unless id
            id = doc.name || 'unknown'
            warn "`#{id}` has no USR. First make sure all modules used in " \
              'your project have been imported. If all used modules are ' \
              'imported, please report this by filing an issue at ' \
              'https://github.com/realm/jazzy/issues along with your Xcode ' \
              'project.'
          end
          doc.url = parents.join('/') + '.html#/' + id
        end
      end
    end

    def self.assert_xcode_location
      expected_xcode_select_path =
        Pathname('/Applications/Xcode.app/Contents/Developer')
      return if xcode_developer_directory == expected_xcode_select_path
      raise 'Please install or symlink Xcode 6.1 or 6.2 in ' \
            "#{expected_xcode_select_path} and set as active developer " \
            'directory by running `sudo xcode-select -s ' \
            "#{expected_xcode_select_path}`"
    end

    def self.xcode_developer_directory
      dir = Pathname(`xcode-select -p`.chomp)
      dir.directory? ? dir.realpath : nil
    end

    def self.assert_swift_version
      swift_version = `xcrun swift --version` =~ /Swift version ([\d\.]+)/ &&
        Regexp.last_match[1]
      expected_swift_version = '1.1'
      return if swift_version == expected_swift_version
      raise "Jazzy only works with Swift #{expected_swift_version}."
    end

    # Run sourcekitten with given arguments and return STDOUT
    def self.run_sourcekitten(arguments)
      assert_xcode_location
      assert_swift_version
      bin_path = Pathname(__FILE__).parent + 'sourcekitten/sourcekitten'
      command = "#{bin_path} #{(arguments).join(' ')}"
      output = `#{command}`
      raise "Running `#{command}` failed: " + output unless $?.success?
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
      doc['key.substructure'].each do |child|
        return true if documented_child?(child)
      end
      false
    end

    def self.should_document?(doc)
      # Always document extensions, since we can't tell what ACL they are
      return true if doc['key.kind'] == 'source.lang.swift.decl.extension'

      SourceDeclaration::AccessControlLevel.new(doc['key.annotated_decl']) >=
        @min_acl
    end

    def self.process_undocumented_token(doc, declaration)
      source_directory = Config.instance.source_directory.to_s
      filepath = doc['key.filepath']
      if filepath && filepath.start_with?(source_directory)
        @undocumented_tokens << doc
      end
      return nil if !documented_child?(doc) && @skip_undocumented
      make_default_doc_info(declaration)
    end

    def self.parameters_from_xml(xml)
      xml.xpath('Parameters/Parameter').map do |parameter_el|
        {
          name: XMLHelper.xpath(parameter_el, 'Name'),
          discussion: Jazzy.markdown.render(
              XMLHelper.xpath(parameter_el, 'Discussion') || '',
            ),
        }
      end
    end

    def self.make_doc_info(doc, declaration)
      return nil unless should_document?(doc)
      xml_key = 'key.doc.full_as_xml'
      return process_undocumented_token(doc, declaration) unless doc[xml_key]

      xml = Nokogiri::XML(doc[xml_key]).root
      declaration.line = XMLHelper.attribute(xml, 'line').to_i
      declaration.column = XMLHelper.attribute(xml, 'column').to_i
      declaration.declaration = Highlighter.highlight(
        doc['key.parsed_declaration'] || XMLHelper.xpath(xml, 'Declaration'),
        'swift',
      )
      declaration.abstract = XMLHelper.xpath(xml, 'Abstract')
      declaration.discussion = XMLHelper.xpath(xml, 'Discussion')
      declaration.return = XMLHelper.xpath(xml, 'ResultDiscussion')

      nodoc = ->(string) { string.to_s.include? '<dt>nodoc</dt>' }
      return if nodoc[declaration.abstract] || nodoc[declaration.discussion]

      declaration.parameters = parameters_from_xml(xml)

      @documented_count += 1
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
    def self.make_source_declarations(docs)
      declarations = []
      current_mark = SourceMark.new
      docs.each do |doc|
        if doc.key?('key.diagnostic_stage')
          declarations += make_source_declarations(doc['key.substructure'])
          next
        end
        declaration = SourceDeclaration.new
        declaration.type = SourceDeclaration::Type.new(doc['key.kind'])
        if declaration.type.mark? && doc['key.name'].start_with?('MARK: ')
          current_mark = SourceMark.new(doc['key.name'])
        end
        next unless declaration.type.should_document?

        unless declaration.type.name
          raise 'Please file an issue at ' \
                'https://github.com/realm/jazzy/issues about adding support ' \
                "for `#{declaration.type.kind}`."
        end

        declaration.file = doc['key.filepath']
        declaration.usr  = doc['key.usr']
        declaration.name = doc['key.name']
        declaration.mark = current_mark
        acl = SourceDeclaration::AccessControlLevel.new(
          doc['key.annotated_decl'],
        )
        declaration.access_control_level = acl

        next unless make_doc_info(doc, declaration)
        make_substructure(doc, declaration)
        declarations << declaration
      end
      declarations
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def self.doc_coverage
      return 0 if @documented_count == 0 && @undocumented_tokens.count == 0
      (100 * @documented_count) /
        (@undocumented_tokens.count + @documented_count)
    end

    def self.deduplicate_declarations(declarations)
      duplicates = declarations.group_by { |d| [d.usr, d.type.kind] }.values
      duplicates.map do |decls|
        decls.first.tap do |d|
          d.children = deduplicate_declarations(decls.flat_map(&:children).uniq)
        end
      end
    end

    # Parse sourcekitten STDOUT output as JSON
    # @return [Hash] structured docs
    def self.parse(sourcekitten_output, min_acl, skip_undocumented)
      @min_acl = min_acl
      @skip_undocumented = skip_undocumented
      sourcekitten_json = JSON.parse(sourcekitten_output)
      docs = make_source_declarations(sourcekitten_json)
      docs = deduplicate_declarations(docs)
      SourceDeclaration::Type.all.each do |type|
        docs = group_docs(docs, type)
      end
      [make_doc_urls(docs, []), doc_coverage, @undocumented_tokens]
    end
  end
end
