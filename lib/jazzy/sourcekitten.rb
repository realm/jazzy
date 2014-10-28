require 'active_support/inflector'

require 'jazzy/config'
require 'jazzy/source_declaration'
require 'jazzy/xml_helper'

module Jazzy
  # This module interacts with the sourcekitten command-line executable
  module SourceKitten
    # Return USR after first digit to get the part that is common to all child
    # elements of this type
    # @example
    #   s:O9Alamofire17ParameterEncoding -> s:FO9Alamofire17ParameterEncoding4JSONFMS0_S0_
    def self.sub_usr(usr)
      usr.slice((usr.index(/\d/))..-1)
    end

    # Recursive function to generate doc hierarchy from flat docs
    # Uses the fact the USR from children is always prefixed by its parent's
    # (after first digit)
    # @see sub_usr
    def self.make_doc_hierarchy(docs, doc)
      sub_usr = sub_usr(doc.usr)
      docs.each do |hashdoc| # rubocop:disable Style/Next
        hash_sub_usr = sub_usr(hashdoc.usr)
        if sub_usr =~ /#{hash_sub_usr}/
          make_doc_hierarchy(hashdoc.children, doc)
          # Stop recursive hierarchy if a match is found
          return
        end
      end
      docs << doc
    end

    # SourceKit-provided token kinds along with their human-readable descriptions
    # @todo Make sure this list is exhaustive for source.lang.swift.decl.*
    def self.kinds
      {
        'source.lang.swift.decl.function.method.class' => 'Class Method',
        'source.lang.swift.decl.var.class' => 'Class Variable',
        'source.lang.swift.decl.class' => 'Class',
        'source.lang.swift.decl.var.global' => 'Constant',
        'source.lang.swift.decl.function.constructor' => 'Constructor',
        'source.lang.swift.decl.function.destructor' => 'Destructor',
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

    # Function to recursively sort docs and its children by line number
    def self.sort_docs_by_line(docs)
      docs.each do |doc|
        doc.children = sort_docs_by_line(doc.children)
      end
      docs.sort_by { |doc| [doc.file, doc.line] }
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

    # Run sourcekitten with given arguments and return combined
    # STDOUT+STDERR output
    def self.run_sourcekitten(arguments)
      bin_path = File.expand_path(File.join(File.dirname(__FILE__), '../../bin'))
      `#{bin_path}/sourcekitten #{(arguments).join(' ')} 2>&1  `
    end

    # Parse sourcekitten STDOUT+STDERR output as XML
    # @return [Hash] structured docs
    def self.parse(sourcekitten_output)
      xml = Nokogiri::XML(sourcekitten_output)
      # Mutable array of docs
      docs = []
      xml.root.element_children.each do |child|
        next if child.name == 'Section' # Skip sections

        declaration = SourceDeclaration.new
        declaration.kind = XMLHelper.xpath(child, 'Kind')

        # Only handle declarations, since sourcekitten will also output
        # references and other kinds
        next unless declaration.kind =~ /^source\.lang\.swift\.decl\..*/

        declaration.kindName = kinds[declaration.kind]

        raise 'Please file an issue on https://github.com/realm/jazzy/issues ' \
          "about adding support for `#{declaration.kind}`"  unless declaration.kindName

        declaration.kindNamePlural = kinds[declaration.kind].pluralize
        declaration.file = XMLHelper.attribute(child, 'file')
        declaration.line = XMLHelper.attribute(child, 'line').to_i
        declaration.column = XMLHelper.attribute(child, 'column').to_i
        declaration.usr = XMLHelper.xpath(child, 'USR')
        declaration.name = XMLHelper.xpath(child, 'Name')
        declaration.declaration = XMLHelper.xpath(child, 'Declaration')
        declaration.abstract = XMLHelper.xpath(child, 'Abstract')
        declaration.discussion = XMLHelper.xpath(child, 'Discussion')
        declaration.return = XMLHelper.xpath(child, 'ResultDiscussion')
        declaration.children = []
        parameters = []
        child.xpath('Parameters/Parameter').each do |parameter_el|
          parameters << {
            name: XMLHelper.xpath(parameter_el, 'Name'),
            discussion: Jazzy.markdown.render(
                XMLHelper.xpath(parameter_el, 'Discussion'),
              ),
          }
        end
        declaration.parameters = parameters if parameters
        docs << declaration
      end

      # docs are flat at this point. let's unflatten them
      root_to_child_sorted_docs = docs.sort_by { |doc| doc.usr.length }

      docs = []
      root_to_child_sorted_docs.each { |doc| make_doc_hierarchy(docs, doc) }
      docs = sort_docs_by_line(docs)
      kinds.keys.each do |kind|
        docs = group_docs(docs, kind)
      end
      make_doc_urls(docs, [])
    end
  end
end
