class Jazzy

  def self.headers(path)
    paths = []
    Find.find(path) do |path|
      if (path =~ /.*\.h$/) && !(path =~ /.*private\.h$/i) && !(path =~ /test.*\//i)
        paths << File.expand_path(path) 
      end
    end
    paths
  end

  def self.document(path)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), '../bin'))

    klass = Jazzy::Klass.new

    string = `#{bin_path}/generate_swift_header.sh #{path}`
    a = string.split(/^\[/); swift = a[0]; rawmap = "[\n"+a[-1]

    rawmap.gsub!(/(key.\w+):/,'"\1":')
    rawmap.gsub!(/(source..+),/,'"\1",')

    xml = `#{bin_path}/ASTDump #{path}`

    doc = Nokogiri::XML(xml)

    results = doc.xpath("//*[@file='#{path}']")

    # Fill in Overview
    top = results.first

    klass[:name] = top.xpath("Name").text
    klass[:usr] = top.xpath("USR").text
    klass[:declaration] = {}
    klass[:declaration][:objc] = top.xpath("Declaration").text.strip
    klass[:abstract] = top.xpath("Abstract/Para").text.strip
    paras = []; top.xpath("./Discussion/Para").each {|p| paras << p.text.strip }
    klass[:discussion] = paras.join("\n\n")

    # Only usable if Swift Header can be correctly generated
    unless rawmap.include? "<<NULL>>"

      swiftmap = {}
      map = {}

      JSON.parse(rawmap).each do |element|

        next unless element["key.name"].downcase == klass[:name].downcase

        # More than one matching element?
        element["key.entities"].each do |e|
          swiftmap[e["key.usr"]] = {}
          swiftmap[e["key.usr"]]["declaration"] = swift.byteslice(e["key.offset"], e["key.length"])
          swiftmap[e["key.usr"]]["name"] = e["key.name"]
        end

        # Inherits
        klass[:inherits] = [] 
        element["key.inherits"].each { |i| klass[:inherits] << { usr: i["key.usr"], name: i["key.name"] } } unless map["key.inherits"].nil?

        # Conforms to
        klass[:conforms] = []
        element["key.conforms"].each { |c| klass[:conforms] << { usr: c["key.usr"], name: c["key.name"] } } unless map["key.conforms"].nil?
      end
    end

    # Import
    klass[:import] = swift.split("\n")[0].chomp.gsub('import ', '')

    # Fill in Properties
    klass[:properties] = []

    results[1..-1].each do |e|
      next unless e.name == "Other"
      property = {}
      property[:usr] = e.xpath("USR").text
      property[:name] = {}
      property[:name][:objc] = e.xpath("Name").text
      if !swiftmap.nil? && swiftmap[property[:usr]]
        property[:name][:swift] = swiftmap[property[:usr]]["name"]
      else
        property[:name][:swift] = "Could not be generated"
      end
      property[:term] = property[:usr]
      property[:declaration] = {}
      property[:declaration][:objc] = e.xpath("Declaration").text.strip
      if !swiftmap.nil? && swiftmap[property[:usr]]
        property[:declaration][:swift] = swiftmap.nil?
      else
        property[:declaration][:swift] = "Could not be generated"
      end
      property[:abstract] = e.xpath("Abstract/Para").text.strip
      paras = []; e.xpath("Discussion/Para").each {|p| paras << p.text.strip }
      property[:discussion] = paras.join("\n\n") unless paras.length == 0
      klass[:properties] << property
    end

    #puts klass[:properties]

    # Fill in Methods
    klass[:methods] = []
    results[1..-1].each do |e|
      next unless e.name == "Function"
      method = {}
      method[:usr] = e.xpath("USR").text
      method[:name] = {}
      method[:name][:objc] = e.xpath("Name").text
      if !swiftmap.nil? && swiftmap[method[:usr]]
        method[:name][:swift] = swiftmap[method[:usr]]["name"]
      else
        method[:name][:swift] = "Could not be generated"
      end
      next if method[:usr].include?('(py)')
      method[:term] = method[:usr].split(')')[-1]
      method[:declaration] = {}
      method[:declaration][:objc] = e.xpath("Declaration").text
      if !swiftmap.nil? && swiftmap[method[:usr]]
        method[:declaration][:swift] = swiftmap[method[:usr]]["declaration"]
      else
        method[:declaration][:swift] = "Could not be generated"
      end
      method[:abstract] = e.xpath("Abstract/Para").text.strip
      paras = []; e.xpath("Discussion/Para").each {|p| paras << p.text.strip }
      method[:discussion] = paras.join("\n\n") unless paras.length == 0
      method[:result] = e.xpath("ResultDiscussion/Para").text.strip

      method[:parameters] = []
      parameters = []; e.xpath("//Parameter").each do |p|
        param = {}
        param[:name] = p.xpath("Name").text
        param[:discussion] = p.xpath("Discussion/Para").text.strip
        method[:parameters] << param
      end

      klass[:methods] << method
    end

    klass.render
  end

  def self.assets(dir)
    Dir.mkdir(File.join(dir,'CSS'))
    Dir.mkdir(File.join(dir,'JavaScript'))
    Dir.mkdir(File.join(dir,'Images'))
    FileUtils.cp_r(Dir[File.expand_path(File.join( File.dirname(__FILE__),'assets/*'))],dir)
  end

end

require 'mustache'
require 'redcarpet'
require 'nokogiri'
require 'json'
require 'active_support/core_ext/hash/conversions'
require 'date'
require 'uri'
require "jazzy/klass.rb"
require "jazzy/jazzhtml.rb"
