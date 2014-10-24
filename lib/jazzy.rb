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

def xml_attribute(node, name)
  node.attributes[name].value if node.attributes[name]
end

def xml_xpath(node, xpath)
  node.xpath(xpath).text if node.xpath(xpath).text.length > 0
end

def subUSR(usr)
  usr.slice((usr.index(/\d/))..-1)
end

def make_doc_hierarchy(docs, doc)
  subUSR = subUSR(doc[:usr])
  docs.each do |hashdoc|
    hashSubUSR = subUSR(hashdoc[:usr])
    if subUSR =~ /#{hashSubUSR}/
      make_doc_hierarchy(hashdoc[:children], doc)
      return
    end
  end
  docs << doc
end

def kinds
  {
    "source.lang.swift.decl.function.method.class" => "Class Method",
    "source.lang.swift.decl.var.class" => "Class Variable",
    "source.lang.swift.decl.class" => "Class",
    "source.lang.swift.decl.var.global" => "Constant",
    "source.lang.swift.decl.function.constructor" => "Constructor",
    "source.lang.swift.decl.enumelement" => "Enum Element",
    "source.lang.swift.decl.enum" => "Enum",
    "source.lang.swift.decl.function.free" => "Function",
    "source.lang.swift.decl.function.method.instance" => "Instance Method",
    "source.lang.swift.decl.var.instance" => "Instance Variable",
    "source.lang.swift.decl.protocol" => "Protocol",
    "source.lang.swift.decl.var.static" => "Static Variable",
    "source.lang.swift.decl.struct" => "Struct",
    "source.lang.swift.decl.function.subscript" => "Subscript",
    "source.lang.swift.decl.typealias" => "Typealias"
  }
end

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

class Jazzy::SourceKitten
  def self.runSourceKitten(arguments)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), "../bin"))
    `#{bin_path}/sourcekitten #{(arguments).join(" ")} 2>&1`
  end

  def self.parse(sourceKittenOutput)
    xml = Nokogiri::XML(sourceKittenOutput)
    docs = []
    xml.root.element_children.each do |child|
      next if child.name == "Section" # Skip sections

      doc = Hash.new
      doc[:kind] = xml_xpath(child, "Kind")
      doc[:kindName] = kinds[doc[:kind]]
      if doc[:kindName] == nil
        puts "Please file an issue on https://github.com/realm/jazzy/issues about adding support for " + doc[:kind]
      end
      doc[:kindNamePlural] = kinds[doc[:kind]].pluralize
      doc[:file] = xml_attribute(child, "file")
      doc[:line] = xml_attribute(child, "line").to_i
      doc[:column] = xml_attribute(child, "column").to_i
      doc[:hasSeparator] = xml_attribute(child, "hasSeparator")
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
    rootToChildSortedDocs = docs.sort { |doc1, doc2| doc1[:usr].length <=> doc2[:usr].length }
    
    docs = []
    rootToChildSortedDocs.each { |doc| make_doc_hierarchy(docs, doc) }
    docs = sort_docs(docs)
    kinds.keys.each do |kind|
      docs = group_docs(docs, kind)
    end
    make_doc_urls(docs, [])
  end
end

def sort_docs(docs)
  docs.each do |doc|
    doc[:children] = sort_docs(doc[:children])
  end
  docs.sort { |doc1, doc2| doc1[:line] <=> doc2[:line] }
end

def make_doc_urls(docs, parents)
  docs.each do |doc|
    if doc[:children].count > 0
      parentsSlash = parents.count > 0 ? "/" : ""
      doc[:url] = parents.join("/") + parentsSlash + doc[:name] + ".html"
      doc[:children] = make_doc_urls(doc[:children], parents + [doc[:name]])
    else
      doc[:url] = parents.join("/") + ".html#/" + doc[:usr]
    end
  end
  docs
end

def prepare_output_dir(output_dir, clean)
  FileUtils.rm_r output_dir if (clean && File.directory?(output_dir))
  FileUtils.mkdir_p output_dir
end

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

class Jazzy::DocBuilder
  def self.buildDocs(outputDir, docs, options, level, doc_structure)
    docs.each do |doc|
      next if doc[:children].count == 0
      prepare_output_dir(outputDir, false)
      path = File.join(outputDir, "#{doc[:name]}.html")
      path_to_root = ['../'].cycle(level).to_a.join("")
      File.open(path, "w") { |file| file.write(Jazzy::DocBuilder.document(options, doc, path_to_root, doc_structure)) }
      Jazzy::DocBuilder.buildDocs(File.join(outputDir, doc[:name]), doc[:children], options, level + 1, doc_structure)
    end
  end

  def self.buildDocsForSourceKittenOutput(sourceKittenOutput, options)
    outputDir = options[:output]
    prepare_output_dir(outputDir, options[:clean])
    docs = Jazzy::SourceKitten.parse(sourceKittenOutput)
    doc_structure = doc_structure_for_docs(docs)
    Jazzy::DocBuilder.buildDocs(outputDir, docs, options, 0, doc_structure)

    # Copy assets into output directory
    FileUtils.cp_r(File.expand_path(File.dirname(__FILE__) + "/../lib/jazzy/assets/") + "/.", outputDir)

    puts "jam out ♪♫ to your fresh new docs at " + outputDir
  end

  def self.document(options, docModel, path_to_root, doc_structure)
    doc = Jazzy::Doc.new
    doc[:name] = docModel[:name]
    doc[:kind] = docModel[:kindName]
    doc[:overview] = $markdown.render(docModel[:abstract])
    doc[:tasks] = []
    doc[:structure] = doc_structure
    tasknames = ["Children"]
    tasknames.each do |taskname|
      items = []
      docModel[:children].each do |subItem|
        item = {
          :name => subItem[:name],
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
    doc[:module_name] = options[:moduleName]
    doc[:author_name] = options[:authorName]
    doc[:author_website] = options[:authorURL]
    doc[:github_link] = options[:githubURL]
    doc[:dash_link] = options[:dashURL]
    doc[:path_to_root] = path_to_root
    doc.render
  end
end
