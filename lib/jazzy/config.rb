require 'optparse'

module Jazzy
  class Config
    attr_accessor :output
    attr_accessor :xcodebuild_arguments
    attr_accessor :author_name
    attr_accessor :module_name
    attr_accessor :github_url
    attr_accessor :github_file_prefix
    attr_accessor :author_url
    attr_accessor :dash_url
    attr_accessor :sourcekitten_sourcefile
    attr_accessor :clean

    def initialize
      self.output = File.expand_path('docs')
      self.xcodebuild_arguments = []
      self.author_name = ''
      self.module_name = ''
      self.github_url = nil
      self.github_file_prefix = nil
      self.author_url = ''
      self.dash_url = nil
      self.sourcekitten_sourcefile = nil
      self.clean = false
    end

    def self.parse!
      config = new
      OptionParser.new do |opt|
        opt.banner = 'Usage: jazzy'
        opt.separator ''
        opt.separator 'Options'

        opt.on('-o', '--output FOLDER', 'Folder to output the HTML docs to') do |output|
          config.output = File.expand_path(output)
        end

        opt.on('-c', '--[no-]clean',
               'Delete contents of output directory before running.',
               'WARNING: If --output is set to ~/Desktop, this will delete the ~/Desktop directory.') do |clean|
          config.clean = clean
        end

        opt.on('-x', '--xcodebuild-arguments arg1,arg2,…argN', Array, 'Arguments to forward to xcodebuild') do |args|
          config.xcodebuild_arguments = args
        end

        opt.on('-a', '--author AUTHOR_NAME', 'Name of author to attribute in docs (i.e. Realm)') do |a|
          config.author_name = a
        end

        opt.on('-u', '--author_url URL', 'Author URL of this project (i.e. http://realm.io)') do |u|
          config.author_url = u
        end

        opt.on('-m', '--module MODULE_NAME', 'Name of module being documented. (i.e. RealmSwift)') do |m|
          config.module_name = m
        end

        opt.on('-d', '--dash_url URL', 'URL to install docs in Dash (i.e. dash-feed://http%3A%2F%2Fcocoadocs.org%2Fdocsets%2FRealm%2FRealm.xml') do |d|
          config.dash_url = d
        end

        opt.on('-g', '--github_url URL', 'GitHub URL of this project (i.e. https://github.com/realm/realm-cocoa)') do |g|
          config.github_url = g
        end

        opt.on('--github-file-prefix PREFIX', 'GitHub URL file prefix of this project (i.e. https://github.com/realm/realm-cocoa/tree/v0.87.1)') do |g|
          config.github_file_prefix = g
        end

        opt.on('-s', '--sourcekitten-sourcefile FILEPATH', 'XML doc file generated from sourcekitten to parse') do |s|
          config.sourcekitten_sourcefile = s
        end

        opt.on('-v', '--version', 'Print version number') do
          puts 'jazzy version: ' + Jazzy::VERSION
          exit
        end

        opt.on('-h', '--help', 'Print this help message') do
          puts opt
          exit
        end
      end.parse!

      config
    end
  end
end
