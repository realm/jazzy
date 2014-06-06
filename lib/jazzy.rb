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

		klass[:name] = "RLMAsset"
		klass[:framework] = "Realm"
		klass[:overview] = "Some very very long overview (top comment of the class)"
		klass[:tasks] = [ { 
		                    name:"Long Title",
		                    shortname: "task1",
		                    css: "active-task",
		                    symbols: [
		                      {
		                        signature: {
		                            swift: "init(fileURL:)",
		                            objc: "initWithFileURL:"
		                        },
		                        method: true,
		                        css: "instance-method",
		                        css2: "x-instance-method",
		                        abstract: "Initializes and returns an asset that points to the specified file.",
		                        declaration: {
		                            swift: "init(fileURL fileURL: NSURL!)",
		                            objc: "(instancetype)initWithFileURL:(NSURL *)fileURL"
		                        },
		                        parameters: {
		                            params: [
		                                {
		                                    term: "fileURL",
		                                    definition: "The URL of the file containing the asset. This parameter must not be nil, and the URL must be a file URL."
		                                }
		                            ]
		                        },
		                        result: "An asset object representing the specified file or nil if the asset could not be initialized.",
		                        discussion: "Use this method to initialize new file-based assets that you want to transfer to iCloud."
		                      },
		                      {
		                        signature: {
		                            swift: "containerIdentifier",
		                            objc: "containerIdentifier"
		                        },
		                        css: "property",
		                        css2: "x-api-property-task-list",
		                        abstract: "Initializes and returns an asset that points to the specified file.",
		                        declaration: {
		                            swift: "var containerIdentifier: String! { get }",
		                            objc: "@property(nonatomic, readonly) NSString *containerIdentifier"
		                        },
		                        result: "An asset object representing the specified file or nil if the asset could not be initialized.",
		                        discussion: "Use this method to initialize new file-based assets that you want to transfer to iCloud."
		                      }
		                    ]
		                  }
		                ]
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
require 'date'
require 'uri'
require "jazzy/klass.rb"
