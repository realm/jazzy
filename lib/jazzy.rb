class Jazzy
	def self.headers(path)
	  paths = []
	  Find.find(path) do |path|
	  	if (path =~ /.*\.h$/) and not (path =~ /.*private\.h$/i) and not (path =~ /test.*\//i)
	    	paths << File.expand_path(path) 
	    end
	   end
	  return paths
	end

	def self.document(path)
		klass = Jazzy::Klass.new

		string = `./bin/generate_swift_header.sh #{path}`
		a = string.split(/^\[/); swift = a[0]; map = "[\n"+a[-1]

		map.gsub!(/(key.\w+):/,'"\1":')
		map.gsub!(/(source..+),/,'"\1",')

		#print map
		#gets

		map = JSON.parse(map)[0]

		swiftmap = {}

		map["key.entities"].each do |e|
			swiftmap[e["key.usr"]] = {}
			swiftmap[e["key.usr"]]["declaration"] = swift.byteslice(e["key.offset"], e["key.length"])
			swiftmap[e["key.usr"]]["name"] = e["key.name"]
		end

		xml = `./bin/ASTDump #{path}`

		doc = Nokogiri::XML(xml)

		# Fill in Overview
		doc.xpath("//Other[1]").each do |e|
			klass[:name] = e.xpath("Name").text
			klass[:usr] = e.xpath("USR").text
			klass[:declaration] = {}
			klass[:declaration][:objc] = e.xpath("Declaration").text.strip
			klass[:abstract] = e.xpath("Abstract/Para").text.strip
			paras = []; e.xpath("./Discussion/Para").each {|p| paras << p.text.strip }
			klass[:discussion] = paras.join("\n\n")
		end
		
		# Fill in Properties
		klass[:properties] = []
		doc.xpath("//Other[position()>1]").each do |e|
			property = {}
			property[:usr] = e.xpath("USR").text
			property[:name] = {}
			property[:name][:objc] = e.xpath("Name").text
			property[:name][:swift] = swiftmap[property[:usr]]["name"]
			property[:term] = property[:usr]
			property[:declaration] = {}
			property[:declaration][:objc] = e.xpath("Declaration").text.strip
			property[:declaration][:swift] = swiftmap[property[:usr]]["declaration"]
			property[:abstract] = e.xpath("Abstract/Para").text.strip
			paras = []; e.xpath("Discussion/Para").each {|p| paras << p.text.strip }
			property[:discussion] = paras.join("\n\n") unless paras.length == 0
			klass[:properties] << property
		end
		ap klass[:properties]

		# Fill in Methods
		klass[:methods] = []
		doc.xpath("//Function").each do |e|
			method = {}
			method[:usr] = e.xpath("USR").text
			method[:name] = {}
			method[:name][:objc] = e.xpath("Name").text
			method[:name][:swift] = swiftmap[method[:usr]]["name"]			
			next if method[:usr].include?('(py)')
			method[:term] = method[:usr].split(')')[-1]
			method[:declaration] = {}
			method[:declaration][:objc] = e.xpath("Declaration").text
			method[:declaration][:swift] = swiftmap[method[:usr]]["declaration"]
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
		ap klass[:methods]

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
require 'awesome_print'
require 'json'
require 'active_support/core_ext/hash/conversions'
require 'date'
require 'uri'
require "jazzy/klass.rb"
require "jazzy/jazzhtml.rb"
