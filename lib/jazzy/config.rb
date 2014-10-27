require 'optparse'

module Jazzy
  class Config
    attr_accessor :input
    attr_accessor :output
    attr_accessor :xcodebuild_arguments
    attr_accessor :authorName
    attr_accessor :moduleName
    attr_accessor :githubURL
    attr_accessor :authorURL
    attr_accessor :dashURL
    attr_accessor :excludes
    attr_accessor :sourcekitten_sourcefile
    attr_accessor :clean

    def initialize
      self.input = File.expand_path(".")
      self.output = File.expand_path("docs")
      self.xcodebuild_arguments = []
      self.authorName = ""
      self.moduleName = ""
      self.githubURL = ""
      self.authorURL = ""
      self.dashURL = ""
      self.excludes = []
      self.sourcekitten_sourcefile = nil
      self.clean = false
    end

    def self.parse!
      config = new
      OptionParser.new do |opt|
        opt.banner = "Usage: jazzy"
        opt.separator  ""
        opt.separator  "Options"

        opt.on("-o", "--output FOLDER", "Folder to output the HTML docs to") do |output|
          config.output = File.expand_path(output)
        end

        opt.on("-e", "--exclude filepath1,filepath2,…filepathN", Array, "Exclude specific files") do |e|
          config.excludes = e
        end

        opt.on("-c", "--[no-]clean",
          "Delete contents of output directory before running.",
          "WARNING: If --output is set to ~/Desktop, this will delete the ~/Desktop directory.") do |clean|
          config.clean = clean
        end

        opt.on("-x", "--xcodebuild-arguments arg1,arg2,…argN", Array, "Arguments to forward to xcodebuild") do |args|
          config.xcodebuild_arguments = args
        end

        opt.on("-a", "--author AUTHOR_NAME", "Name of author to attribute in docs (i.e. Realm)") do |a|
          config.authorName = a
        end

        opt.on("-u", "--author_url URL", "Author URL of this project (i.e. http://realm.io)") do |u|
          config.authorURL = u
        end

        opt.on("-m", "--module MODULE_NAME", "Name of module being documented. (i.e. RealmSwift)") do |m|
          config.moduleName = m
        end

        opt.on("-d", "--dash_url URL", "URL to install docs in Dash (i.e. dash-feed://http%3A%2F%2Fcocoadocs.org%2Fdocsets%2FRealm%2FRealm.xml") do |d|
          config.dashURL = d
        end

        opt.on("-g", "--github_url URL", "GitHub URL of this project (i.e. https://github.com/realm/realm-cocoa)") do |g|
          config.githubURL = g
        end

        opt.on("-s", "--sourcekitten-sourcefile FILEPATH", "XML doc file generated from sourcekitten to parse") do |s|
          config.sourcekitten_sourcefile = s
        end

        opt.on("-v", "--version", "Print version number") do
          puts "jazzy version: " + Jazzy::VERSION
          exit
        end

        opt.on("-h", "--help", "Print this help message") do
          puts opt_parser
          exit
        end
      end.parse!

      config
    end
  end
end
