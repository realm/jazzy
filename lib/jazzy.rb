require 'mustache'
require 'redcarpet'
require 'nokogiri'
require 'json'
require 'date'
require 'uri'
require 'active_support/inflector'
require 'fileutils'
require 'jazzy/gem_version.rb'
require 'jazzy/doc.rb'
require 'jazzy/jazzy_markdown.rb'
require 'jazzy/config'
require 'jazzy/xml_helper'
require 'jazzy/source_declaration'

# XML Helpers

# Gets value of XML attribute or nil
# (i.e. file in <Class file="Musician.swift"></Class>)
def xml_attribute(node, name)
  node.attributes[name].value if node.attributes[name]
end

# Gets text in XML node or nil (i.e. s:cMyUSR <USR>s:cMyUSR</USR>)
def xml_xpath(node, xpath)
  node.xpath(xpath).text if node.xpath(xpath).text.length > 0
end

# Return USR after first digit to get the part that is common to all child
# elements of this type
# @example
#   s:O9Alamofire17ParameterEncoding -> s:FO9Alamofire17ParameterEncoding4JSONFMS0_S0_
def sub_usr(usr)
  usr.slice((usr.index(/\d/))..-1)
end

# Recursive function to generate doc hierarchy from flat docs
# Uses the fact the USR from children is always prefixed by its parent's
# (after first digit)
# @see sub_usr
def make_doc_hierarchy(docs, doc)
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
def kinds
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
def group_docs(docs, kind)
  kind_name_plural = kinds[kind].pluralize
  group, docs = docs.partition { |doc| doc.kind == kind }
  docs << Jazzy::SourceDeclaration.new.tap do |sd|
    sd.name = kind_name_plural
    sd.kind = 'Overview'
    sd.abstract = "The following #{kind_name_plural.downcase} are available " \
      'globally.'
    sd.children = group
  end if group.count > 0
  docs
end

# This module interacts with the sourcekitten command-line executable
module Jazzy
  module SourceKitten
    # Run sourcekitten with given arguments and return combined
    # STDOUT+STDERR output
    def self.run_sourcekitten(arguments)
      bin_path = File.expand_path(File.join(File.dirname(__FILE__), '../bin'))
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
        declaration.kind = xml_xpath(child, 'Kind')

        # Only handle declarations, since sourcekitten will also output
        # references and other kinds
        next unless declaration.kind =~ /^source\.lang\.swift\.decl\..*/

        declaration.kindName = kinds[declaration.kind]

        raise 'Please file an issue on https://github.com/realm/jazzy/issues ' \
          "about adding support for `#{declaration.kind}`"  unless declaration.kindName

        declaration.kindNamePlural = kinds[declaration.kind].pluralize
        declaration.file = xml_attribute(child, 'file')
        declaration.line = xml_attribute(child, 'line').to_i
        declaration.column = xml_attribute(child, 'column').to_i
        declaration.usr = xml_xpath(child, 'USR')
        declaration.name = xml_xpath(child, 'Name')
        declaration.declaration = xml_xpath(child, 'Declaration')
        declaration.abstract = xml_xpath(child, 'Abstract')
        declaration.discussion = xml_xpath(child, 'Discussion')
        declaration.return = xml_xpath(child, 'ResultDiscussion')
        declaration.children = []
        parameters = []
        child.xpath('Parameters/Parameter').each do |parameter_el|
          parameters << {
            name: xml_xpath(parameter_el, 'Name'),
            discussion: Jazzy.markdown.render(
                xml_xpath(parameter_el, 'Discussion'),
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

# Function to recursively sort docs and its children by line number
def sort_docs_by_line(docs)
  docs.each do |doc|
    doc.children = sort_docs_by_line(doc.children)
  end
  docs.sort_by { |doc| [doc.file, doc.line] }
end

# Generate doc URL by prepending its parents URLs
# @return [Hash] input docs with URLs
def make_doc_urls(docs, parents)
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

# mkdir -p output directory and clean if option is set
def prepare_output_dir(output_dir, clean)
  FileUtils.rm_r output_dir if clean && File.directory?(output_dir)
  FileUtils.mkdir_p output_dir
end

# Generate doc structure to be used in sidebar navigation
# @return [Array] doc structure comprised of section names and child names and URLs
def doc_structure_for_docs(docs)
  structure = []
  docs.each do |doc|
    structure << {
      section: doc.name,
      children: doc.children.map { |child| { name: child.name, url: child.url } },
    }
  end
  structure
end

module Jazzy
  # This module handles HTML generation, file writing, asset copying,
  # and generally building docs given sourcekitten output
  module DocBuilder
    # Build documentation from the given options
    # @param [Config] options
    def self.build(options)
      if options.sourcekitten_sourcefile
        file = File.open(options.sourcekitten_sourcefile)
        file_contents = file.read
        file.close
        build_docs_for_sourcekitten_output(file_contents, options)
      else
        sourcekitten_output = Jazzy::SourceKitten.run_sourcekitten(options.xcodebuild_arguments)
        sourcekitten_exit_code = $?.exitstatus
        if sourcekitten_exit_code == 0
          build_docs_for_sourcekitten_output(sourcekitten_output, options)
        else
          warn sourcekitten_output
          warn 'Please pass in xcodebuild arguments using -x'
          exit sourcekitten_exit_code
        end
      end
    end

    # Build & write HTML docs to disk from structured docs array
    # @param [String] output_dir Root directory to write docs
    # @param [Array] docs Array of structured docs
    # @param [Config] options Build options
    # @param [Integer] depth Number of parents. Used to calculate path_to_root
    #        for web.
    # @param [Array] doc_structure @see #doc_structure_for_docs
    def self.build_docs(output_dir, docs, options, depth, doc_structure)
      docs.each do |doc|
        next if doc.name != 'index' && doc.children.count == 0
        prepare_output_dir(output_dir, false)
        path = File.join(output_dir, "#{doc.name}.html")
        path_to_root = ['../'].cycle(depth).to_a.join('')
        File.open(path, 'w') { |file| file.write(Jazzy::DocBuilder.document(options, doc, path_to_root, doc_structure)) }
        if doc.name != 'index'
          Jazzy::DocBuilder.build_docs(File.join(output_dir, doc.name), doc.children, options, depth + 1, doc_structure)
        end
      end
    end

    # Build docs given sourcekitten output
    # @param [String] sourcekitten_output Output of sourcekitten command
    # @param [Config] options Build options
    def self.build_docs_for_sourcekitten_output(sourcekitten_output, options)
      output_dir = options.output
      prepare_output_dir(output_dir, options.clean)
      docs = Jazzy::SourceKitten.parse(sourcekitten_output)
      doc_structure = doc_structure_for_docs(docs)
      docs << SourceDeclaration.new.tap { |sd| sd.name = 'index' }
      Jazzy::DocBuilder.build_docs(output_dir, docs, options, 0, doc_structure)

      # Copy assets into output directory
      assets_dir = File.expand_path(File.dirname(__FILE__) + '/../lib/jazzy/assets/') + '/.'
      FileUtils.cp_r(assets_dir, output_dir)

      puts 'jam out ♪♫ to your fresh new docs at ' + output_dir
    end

    # Build Mustache document from single parsed doc
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see Jazzy::SourceKitten.parse
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document(options, doc_model, path_to_root, doc_structure)
      doc = Jazzy::Doc.new # Mustache model instance
      # Do something special for index.
      # @todo render README here
      if doc_model.name == 'index'
        doc[:name] = options.module_name
        doc[:overview] = Jazzy.markdown.render(
          "This is the index page for #{options.module_name} docs. " \
          'Navigate using the links on the left.',
        )
        doc[:structure] = doc_structure
        doc[:module_name] = options.module_name
        doc[:author_name] = options.author_name
        doc[:author_website] = options.author_url
        doc[:github_link] = options.github_url
        doc[:dash_link] = options.dash_url
        doc[:path_to_root] = path_to_root
        return doc.render
      end

      ########################################################
      # Map doc_model values to mustache model values
      ########################################################

      doc[:name] = doc_model.name
      doc[:kind] = doc_model.kindName
      doc[:overview] = Jazzy.markdown.render(doc_model.abstract)
      doc[:tasks] = []
      doc[:structure] = doc_structure
      # @todo parse mark-style comments and use as task names
      tasknames = ['Children']
      tasknames.each do |taskname|
        items = []
        doc_model.children.each do |subItem|
          # Combine abstract and discussion into abstract
          abstract = (subItem.abstract || '') + (subItem.discussion || '')
          item = {
            name: subItem.name,
            abstract: Jazzy.markdown.render(abstract),
            declaration: subItem.declaration,
            usr: subItem.usr,
          }
          item[:return] = Jazzy.markdown.render(subItem.return) if subItem.return
          parameters = subItem.parameters
          item[:parameters] = parameters if parameters.length > 0
          items << item
        end
        doc[:tasks] << {
          name: '',
          uid: URI.encode(taskname),
          items: items,
        }
      end
      doc[:module_name] = options.module_name
      doc[:author_name] = options.author_name
      doc[:author_website] = options.author_url
      doc[:github_link] = options.github_url
      doc[:dash_link] = options.dash_url
      doc[:path_to_root] = path_to_root
      doc.render
    end
  end
end
