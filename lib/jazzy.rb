require "mustache"
require "redcarpet"
require "nokogiri"
require "json"
require "date"
require "uri"
require "active_support/inflector"
require "jazzy/gem_version.rb"
require "jazzy/doc.rb"
require "jazzy/jazzy_markdown.rb"

# XML Helpers

# Gets value of XML attribute or nil (i.e. file in <Class file="Musician.swift"></Class>)
def xml_attribute(node, name)
  node.attributes[name].value if node.attributes[name]
end

# Gets text in XML node or nil (i.e. s:cMyUSR <USR>s:cMyUSR</USR>)
def xml_xpath(node, xpath)
  node.xpath(xpath).text if node.xpath(xpath).text.length > 0
end

# Return USR after first digit to get the part that is common to all child elements of this type
# @example
#   s:O9Alamofire17ParameterEncoding -> s:FO9Alamofire17ParameterEncoding4JSONFMS0_S0_
def subUSR(usr)
  usr.slice((usr.index(/\d/))..-1)
end

# Recursive function to generate doc hierarchy from flat docs
# Uses the fact the USR from children is always prefixed by its parent's (after first digit)
# @see subUSR
def make_doc_hierarchy(docs, doc)
  subUSR = subUSR(doc[:usr])
  docs.each do |hashdoc|
    hashSubUSR = subUSR(hashdoc[:usr])
    if subUSR =~ /#{hashSubUSR}/
      make_doc_hierarchy(hashdoc[:children], doc)
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
    "source.lang.swift.decl.function.method.class" => "Class Method",
    "source.lang.swift.decl.var.class" => "Class Variable",
    "source.lang.swift.decl.class" => "Class",
    "source.lang.swift.decl.var.global" => "Constant",
    "source.lang.swift.decl.function.constructor" => "Constructor",
    "source.lang.swift.decl.enumelement" => "Enum Element",
    "source.lang.swift.decl.enum" => "Enum",
    "source.lang.swift.decl.extension" => "Extension",
    "source.lang.swift.decl.function.free" => "Function",
    "source.lang.swift.decl.function.method.instance" => "Instance Method",
    "source.lang.swift.decl.var.instance" => "Instance Variable",
    "source.lang.swift.decl.var.parameter" => "Parameter",
    "source.lang.swift.decl.protocol" => "Protocol",
    "source.lang.swift.decl.function.method.static" => "Static Method",
    "source.lang.swift.decl.var.static" => "Static Variable",
    "source.lang.swift.decl.struct" => "Struct",
    "source.lang.swift.decl.function.subscript" => "Subscript",
    "source.lang.swift.decl.typealias" => "Typealias"
  }
end

# Group root-level docs by kind and add as children to a group doc element
def group_docs(docs, kind)
  kindNamePlural = kinds[kind].pluralize
  group = docs.select { |doc| doc[:kind] == kind }
  docs = docs.select { |doc| doc[:kind] != kind }
  docs << {
    :name => kindNamePlural,
    :kind => "Overview",
    :abstract => "The following #{kindNamePlural.downcase} are available globally.",
    :children => group
  } if group.count > 0
  docs
end

# This module interacts with the sourcekitten command-line executable
module Jazzy::SourceKitten
  # Run sourcekitten with given arguments and return combined STDOUT+STDERR output
  def self.runSourceKitten(arguments)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), "../bin"))
    `#{bin_path}/sourcekitten #{(arguments).join(" ")} 2>&1`
  end

  # Parse sourcekitten STDOUT+STDERR output as XML
  # @return [Hash] structured docs
  def self.parse(sourceKittenOutput)
    xml = Nokogiri::XML(sourceKittenOutput)
    # Mutable array of docs
    docs = []
    xml.root.element_children.each do |child|
      next if child.name == "Section" # Skip sections

      doc = Hash.new
      doc[:kind] = xml_xpath(child, "Kind")
      
      # Only handle declarations, since sourcekitten will also output references and other kinds
      next unless doc[:kind] =~ /^source\.lang\.swift\.decl\..*/

      doc[:kindName] = kinds[doc[:kind]]
      if doc[:kindName] == nil
        raise "Please file an issue on https://github.com/realm/jazzy/issues about adding support for " + doc[:kind]
      end
      doc[:kindNamePlural] = kinds[doc[:kind]].pluralize
      doc[:file] = xml_attribute(child, "file")
      doc[:line] = xml_attribute(child, "line").to_i
      doc[:column] = xml_attribute(child, "column").to_i
      doc[:usr] = xml_xpath(child, "USR")
      doc[:name] = xml_xpath(child, "Name")
      doc[:declaration] = xml_xpath(child, "Declaration")
      doc[:abstract] = xml_xpath(child, "Abstract")
      doc[:discussion] = xml_xpath(child, "Discussion")
      doc[:return] = xml_xpath(child, "ResultDiscussion")
      doc[:children] = []
      parameters = []
      child.xpath("Parameters/Parameter").each do |parameter_el|
        parameters << {
          :name => xml_xpath(parameter_el, "Name"),
          :discussion => $markdown.render(xml_xpath(parameter_el, "Discussion"))
        }
      end
      doc[:parameters] = parameters if parameters
      docs << doc
    end

    # docs are flat at this point. let's unflatten them
    rootToChildSortedDocs = docs.sort_by { |doc| doc[:usr].length }
    
    docs = []
    rootToChildSortedDocs.each { |doc| make_doc_hierarchy(docs, doc) }
    docs = sort_docs_by_line(docs)
    kinds.keys.each do |kind|
      docs = group_docs(docs, kind)
    end
    make_doc_urls(docs, [])
  end
end

# Function to recursively sort docs and its children by line number
def sort_docs_by_line(docs)
  docs.each do |doc|
    doc[:children] = sort_docs_by_line(doc[:children])
  end
  docs.sort_by { |doc| [doc[:file], doc[:line]] }
end

# Generate doc URL by prepending its parents URLs
# @return [Hash] input docs with URLs
def make_doc_urls(docs, parents)
  docs.each do |doc|
    if doc[:children].count > 0
      # Create HTML page for this doc if it has children
      parentsSlash = parents.count > 0 ? "/" : ""
      doc[:url] = parents.join("/") + parentsSlash + doc[:name] + ".html"
      doc[:children] = make_doc_urls(doc[:children], parents + [doc[:name]])
    else
      # Don't create HTML page for this doc if it doesn't have children
      # Instead, make its link a hash-link on its parent's page
      doc[:url] = parents.join("/") + ".html#/" + doc[:usr]
    end
  end
  docs
end

# mkdir -p output directory and clean if option is set
def prepare_output_dir(output_dir, clean)
  FileUtils.rm_r output_dir if (clean && File.directory?(output_dir))
  FileUtils.mkdir_p output_dir
end

# Generate doc structure to be used in sidebar navigation
# @return [Array] doc structure comprised of section names and child names and URLs
def doc_structure_for_docs(docs)
  structure = []
  docs.each do |doc|
    structure << {
      :section => doc[:name],
      :children => doc[:children].map { |child| {:name => child[:name], :url => child[:url]} }
    }
  end
  structure
end

# This module handles HTML generation, file writing, asset copying, and generally building docs given sourcekitten output
module Jazzy::DocBuilder
  # Build & write HTML docs to disk from structured docs array
  # @param [String] outputDir Root directory to write docs
  # @param [Array] docs Array of structured docs
  # @param [Config] options Build options
  # @param [Integer] depth Number of parents. Used to calculate path_to_root for web.
  # @param [Array] doc_structure @see #doc_structure_for_docs
  def self.buildDocs(outputDir, docs, options, depth, doc_structure)
    docs.each do |doc|
      next if doc[:name] != "index" && doc[:children].count == 0
      prepare_output_dir(outputDir, false)
      path = File.join(outputDir, "#{doc[:name]}.html")
      path_to_root = ['../'].cycle(depth).to_a.join("")
      File.open(path, "w") { |file| file.write(Jazzy::DocBuilder.document(options, doc, path_to_root, doc_structure)) }
      if doc[:name] != "index"
        Jazzy::DocBuilder.buildDocs(File.join(outputDir, doc[:name]), doc[:children], options, depth + 1, doc_structure)
      end
    end
  end

  # Build docs given sourcekitten output
  # @param [String] sourceKittenOutput Output of sourcekitten command
  # @param [Config] options Build options
  def self.buildDocsForSourceKittenOutput(sourceKittenOutput, options)
    outputDir = options.output
    prepare_output_dir(outputDir, options.clean)
    docs = Jazzy::SourceKitten.parse(sourceKittenOutput)
    doc_structure = doc_structure_for_docs(docs)
    docs << {:name => "index"}
    Jazzy::DocBuilder.buildDocs(outputDir, docs, options, 0, doc_structure)

    # Copy assets into output directory
    FileUtils.cp_r(File.expand_path(File.dirname(__FILE__) + "/../lib/jazzy/assets/") + "/.", outputDir)

    puts "jam out ♪♫ to your fresh new docs at " + outputDir
  end

  # Build Mustache document from single parsed doc
  # @param [Config] options Build options
  # @param [Hash] docModel Parsed doc. @see Jazzy::SourceKitten.parse
  # @param [String] path_to_root
  # @param [Array] doc_structure doc structure comprised of section names and child names and URLs. @see doc_structure_for_docs
  def self.document(options, docModel, path_to_root, doc_structure)
    doc = Jazzy::Doc.new # Mustache model instance
    # Do something special for index.
    # @todo render README here
    if docModel[:name] == "index"
      doc[:name] = options.moduleName
      doc[:overview] = $markdown.render("This is the index page for #{options.moduleName} docs. Navigate using the links on the left.")
      doc[:structure] = doc_structure
      doc[:module_name] = options.moduleName
      doc[:author_name] = options.authorName
      doc[:author_website] = options.authorURL
      doc[:github_link] = options.githubURL
      doc[:dash_link] = options.dashURL
      doc[:path_to_root] = path_to_root
      return doc.render
    end

    ########################################################
    # Map docModel values to mustache model values
    ########################################################

    doc[:name] = docModel[:name]
    doc[:kind] = docModel[:kindName]
    doc[:overview] = $markdown.render(docModel[:abstract])
    doc[:tasks] = []
    doc[:structure] = doc_structure
    # @todo parse mark-style comments and use as task names
    tasknames = ["Children"]
    tasknames.each do |taskname|
      items = []
      docModel[:children].each do |subItem|
        item = {
          :name => subItem[:name],
          # Combine abstract and discussion into abstract
          :abstract => $markdown.render((subItem[:abstract] || "") + (subItem[:discussion] || "")),
          :declaration => subItem[:declaration],
          :usr => subItem[:usr]
        }
        item[:return] = $markdown.render(subItem[:return]) if subItem[:return]
        parameters = subItem[:parameters]
        item[:parameters] = parameters if parameters.length > 0
        items << item
      end
      doc[:tasks] << {
        :name => "",
        :uid => URI::encode(taskname),
        :items => items
      }
    end
    doc[:module_name] = options.moduleName
    doc[:author_name] = options.authorName
    doc[:author_website] = options.authorURL
    doc[:github_link] = options.githubURL
    doc[:dash_link] = options.dashURL
    doc[:path_to_root] = path_to_root
    doc.render
  end
end
