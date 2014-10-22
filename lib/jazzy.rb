require 'mustache'
require 'redcarpet'
require 'nokogiri'
require 'json'
require 'date'
require 'uri'
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

class Jazzy::SourceKitten
  def self.runSourceKitten(arguments)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), '../bin'))
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
    docs
  end
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
    classes = docs.select { |doc| doc[:kind] == "Class" && doc[:declaration] =~ /class/ }
    classes.each do |theClass|
      classUSR = theClass[:usr]
      subItems = docs.select { |doc| doc[:usr] != classUSR && doc[:usr] =~ /#{classUSR[3..-1]}/ }
      path = File.join(outputDir, "#{theClass[:name]}.html")
      File.open(path, 'w') { |file| file.write(Jazzy::DocBuilder.document(options, theClass, subItems)) }
    end

    # Copy assets into output directory
    FileUtils.cp_r(File.expand_path(File.dirname(__FILE__) + '/../lib/jazzy/assets/') + '/.', outputDir)

    puts "Docs successfully built at " + outputDir
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
