require 'active_support/inflector'
require 'json'
require 'open3'

require 'jazzy/config'
require 'jazzy/source_declaration'
require 'jazzy/xml_helper'

module Jazzy
  # This module interacts with the sourcekitten command-line executable
  module SourceKitten
    # SourceKit-provided token kinds along with their human-readable descriptions
    # @todo Make sure this list is exhaustive for source.lang.swift.decl.*
    def self.kinds
      {
        'source.lang.swift.decl.function.method.class' => 'Class Method',
        'source.lang.swift.decl.var.class' => 'Class Variable',
        'source.lang.swift.decl.class' => 'Class',
        'source.lang.swift.decl.function.constructor' => 'Constructor',
        'source.lang.swift.decl.function.destructor' => 'Destructor',
        'source.lang.swift.decl.var.global' => 'Global Variable',
        'source.lang.swift.decl.enumelement' => 'Enum Element',
        'source.lang.swift.decl.enum' => 'Enum',
        'source.lang.swift.decl.extension' => 'Extension',
        'source.lang.swift.decl.function.free' => 'Function',
        'source.lang.swift.decl.function.method.instance' => 'Instance Method',
        'source.lang.swift.decl.var.instance' => 'Instance Variable',
        'source.lang.swift.decl.var.local' => 'Local Variable',
        'source.lang.swift.decl.var.parameter' => 'Parameter',
        'source.lang.swift.decl.protocol' => 'Protocol',
        'source.lang.swift.decl.function.method.static' => 'Static Method',
        'source.lang.swift.decl.var.static' => 'Static Variable',
        'source.lang.swift.decl.struct' => 'Struct',
        'source.lang.swift.decl.function.subscript' => 'Subscript',
        'source.lang.swift.decl.typealias' => 'Typealias',
      }
    end

    # Group root-level docs by kind and add as children to a group doc element
    def self.group_docs(docs, kind)
      kind_name_plural = kinds[kind].pluralize
      group, docs = docs.partition { |doc| doc.kind == kind }
      docs << SourceDeclaration.new.tap do |sd|
        sd.name = kind_name_plural
        sd.kind = 'Overview'
        sd.abstract = "The following #{kind_name_plural.downcase} are available " \
          'globally.'
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
          doc.url = parents.join('/') + '.html#/' + doc.usr
        end
      end
      docs
    end

    # Run sourcekitten with given arguments and return
    # STDOUT, STDERR and exit status
    def self.run_sourcekitten(arguments)
      bin_path = File.expand_path(File.join(File.dirname(__FILE__), '../../bin'))
      Open3.capture3("#{bin_path}/sourcekitten #{(arguments).join(' ')}")
    end

    def self.make_source_declarations(docs)
      declarations = []
      docs.each do |doc|
        if doc.key?('key.diagnostic_stage')
          declarations += make_source_declarations(doc['key.substructure'])
          next
        end
        declaration = SourceDeclaration.new
        declaration.kind = doc['key.kind']
        next unless declaration.kind =~ /^source\.lang\.swift\.decl\..*/
        next if declaration.kind == 'source.lang.swift.decl.var.parameter'

        declaration.kindName = kinds[declaration.kind]

        raise 'Please file an issue on https://github.com/realm/jazzy/issues ' \
          "about adding support for `#{declaration.kind}`" unless declaration.kindName

        declaration.kindNamePlural = declaration.kindName.pluralize
        declaration.file = doc['key.filepath']
        declaration.usr = doc['key.usr']
        declaration.name = doc['key.name']

        if doc['key.doc.full_as_xml']
          xml = Nokogiri::XML(doc['key.doc.full_as_xml']).root
          declaration.line = XMLHelper.attribute(xml, 'line').to_i
          declaration.column = XMLHelper.attribute(xml, 'column').to_i
          declaration.declaration = XMLHelper.xpath(xml, 'Declaration')
          declaration.abstract = XMLHelper.xpath(xml, 'Abstract')
          declaration.discussion = XMLHelper.xpath(xml, 'Discussion')
          declaration.return = XMLHelper.xpath(xml, 'ResultDiscussion')

          parameters = []
          xml.xpath('Parameters/Parameter').each do |parameter_el|
            parameters << {
              name: XMLHelper.xpath(parameter_el, 'Name'),
              discussion: Jazzy.markdown.render(
                  XMLHelper.xpath(parameter_el, 'Discussion'),
                ),
            }
          end
          declaration.parameters = parameters
        else
          # @todo: Fix these
          declaration.line = 0
          declaration.column = 0
          declaration.abstract = 'Undocumented'
          declaration.parameters = []
        end

        if doc['key.substructure']
          declaration.children = make_source_declarations(doc['key.substructure'])
        else
          declaration.children = []
        end
        declarations << declaration
      end
      declarations
    end

    # Parse sourcekitten STDOUT+STDERR output as JSON
    # @return [Hash] structured docs
    def self.parse(sourcekitten_output)
      docs = make_source_declarations(JSON.parse(sourcekitten_output))
      kinds.keys.each do |kind|
        docs = group_docs(docs, kind)
      end
      make_doc_urls(docs, [])
    end
  end
end
