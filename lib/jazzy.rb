require 'mustache'
require 'redcarpet'
require 'nokogiri'
require 'json'
require 'date'
require 'uri'
require "jazzy/gem_version.rb"
require "jazzy/doc.rb"
require "jazzy/jazzy_markdown.rb"

class Jazzy::SourceKitten
  def self.runSourceKitten(arguments)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), '../bin'))
    `#{bin_path}/sourcekitten #{(arguments).join(" ")}`
  end

  def self.parse(sourceKittenOutput)
    xml = Nokogiri::XML(sourceKittenOutput)
    docs = []
    for child in xml.root.element_children
      # puts child.inspect
      # break
      doc = Hash.new
      doc[:kind] = child.name
      doc[:file] = child.attributes["file"].value
      doc[:line] = child.attributes["line"].value
      doc[:column] = child.attributes["column"].value if child.attributes["column"]
      doc[:hasSeparator] = child.attributes["hasSeparator"].value if child.attributes["hasSeparator"]
      doc[:usr] = child.xpath("USR").text if child.xpath("USR").text.length > 0
      doc[:name] = child.xpath("Name").text if child.xpath("Name").text.length > 0
      doc[:declaration] = child.xpath("Declaration").text if child.xpath("Declaration").text.length > 0
      docs << doc
    end
    docs
  end
end

class Jazzy::DocBuilder
  def self.buildDocsForSourceKittenOutput(sourceKittenOutput, outputDir)
    docs = Jazzy::SourceKitten.parse(sourceKittenOutput)
    classes = docs.select { |doc| doc[:kind] == "Class" && doc[:declaration] =~ /class/ }

    classes.each do |theClass|
      path = File.join(outputDir, "#{theClass[:name]}.html")
      File.open(path, 'w') { |file| file.write(Jazzy::DocBuilder.document(theClass)) }
    end

    # Copy assets into output directory
    FileUtils.cp_r(File.expand_path(File.dirname(__FILE__) + '/../lib/jazzy/assets/') + '/.', outputDir)
  end

  def self.document(theClass)
    doc = Jazzy::Doc.new
    doc[:name] = theClass[:name]
    doc[:kind] = "Class"
    doc[:overview] = $markdown.render("#{theClass[:name]} is a generic class (roughly the Swift equivalent of `RLMArray`).")
    taskname = "Creating a #{theClass[:name]}"
    doc[:tasks] = [
      {
        :name => taskname,
        :uid => URI::encode(taskname),
        :abstract => $markdown.render("This is the abstract for the constructor."),
        :declaration => "init(string aString: String)",
        :parameters => [:name => "aString", :description => $markdown.render("The characters for the new object.")],
        :return => $markdown.render("a `#{theClass[:name]}` object initialized with the characters of `aString` and no attribute information.")
      }
    ]
    doc[:module_name] = "RealmSwift"
    doc[:company_name] = "Realm"
    doc[:company_website] = "http://realm.io"
    doc[:github_link] = "https://github.com/realm/realm-cocoa"
    doc[:dash_link] = "http://kapeli.com/dash"
    doc.render
  end
end
