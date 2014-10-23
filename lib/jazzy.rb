require "mustache"
require "redcarpet"
require "nokogiri"
require "json"
require "date"
require "uri"
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

class Jazzy::SourceKitten
  def self.runSourceKitten(arguments)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), "../bin"))
    `#{bin_path}/sourcekitten #{(arguments).join(" ")} 2>&1`
  end

  def self.parse(sourceKittenOutput)
    xml = Nokogiri::XML(sourceKittenOutput)
    docs = []
    xml.root.element_children.each do |child|
      doc = Hash.new
      doc[:kind] = child.name
      doc[:file] = xml_attribute(child, "file")
      doc[:line] = xml_attribute(child, "line")
      doc[:column] = xml_attribute(child, "column")
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
    docs_with_usrs = docs.select { |doc| doc[:usr] != nil }
    rootToChildSortedDocs = docs_with_usrs.sort { |doc1, doc2| doc1[:usr].length <=> doc2[:usr].length }
    
    docs = []
    rootToChildSortedDocs.each { |doc| make_doc_hierarchy(docs, doc) }
    sort_docs(docs)
  end
end

def sort_docs(docs)
  docs.each do |doc|
    doc[:children] = sort_docs(doc[:children])
  end
  docs.sort { |doc1, doc2| doc1[:line].to_i <=> doc2[:line].to_i }
end

def prepare_output_dir(output_dir, clean)
  FileUtils.rm_r output_dir if (clean && File.directory?(output_dir))
  FileUtils.mkdir_p output_dir
end

class Jazzy::DocBuilder
  def self.buildDocsForSourceKittenOutput(sourceKittenOutput, options)
    outputDir = options[:output]
    prepare_output_dir(outputDir, options[:clean])
    docs = Jazzy::SourceKitten.parse(sourceKittenOutput)
    docs.each do |doc|
      path = File.join(outputDir, "#{doc[:name]}.html")
      File.open(path, "w") { |file| file.write(Jazzy::DocBuilder.document(options, doc, doc[:children])) }
    end

    # Copy assets into output directory
    FileUtils.cp_r(File.expand_path(File.dirname(__FILE__) + "/../lib/jazzy/assets/") + "/.", outputDir)

    puts "jam out ♪♫ to your fresh new docs at " + outputDir
  end

  def self.document(options, theClass, subItems)
    doc = Jazzy::Doc.new
    doc[:name] = theClass[:name]
    doc[:kind] = theClass[:kind]
    doc[:overview] = $markdown.render(theClass[:abstract])
    doc[:tasks] = []
    tasknames = ["Children"]
    tasknames.each do |taskname|
      items = []
      subItems.each do |subItem|
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
        :name => taskname,
        :uid => URI::encode(taskname),
        :items => items
      }
    end
    doc[:module_name] = options[:moduleName]
    doc[:author_name] = options[:authorName]
    doc[:author_website] = options[:authorURL]
    doc[:github_link] = options[:githubURL]
    doc[:dash_link] = options[:dashURL]
    doc.render
  end
end
