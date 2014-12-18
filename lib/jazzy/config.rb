require 'optparse'
require 'pathname'
require 'uri'

require 'jazzy/source_declaration/access_control_level'

module Jazzy
  # rubocop:disable Metrics/ClassLength
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
    attr_accessor :readme_path
    attr_accessor :docset_platform
    attr_accessor :root_url
    attr_accessor :version
    attr_accessor :min_acl

    def initialize
      self.output = Pathname('docs')
      self.xcodebuild_arguments = []
      self.author_name = ''
      self.module_name = ''
      self.author_url = URI('')
      self.clean = false
      self.docset_platform = 'jazzy'
      self.version = '1.0'
      self.min_acl = SourceDeclaration::AccessControlLevel.internal
    end

    # rubocop:disable Metrics/MethodLength
    def self.parse!
      config = new
      OptionParser.new do |opt|
        opt.banner = 'Usage: jazzy'
        opt.separator ''
        opt.separator 'Options'

        opt.on('-o', '--output FOLDER',
               'Folder to output the HTML docs to') do |output|
          config.output = Pathname(output)
        end

        opt.on('-c', '--[no-]clean',
               'Delete contents of output directory before running.',
               'WARNING: If --output is set to ~/Desktop, this will delete the \
                ~/Desktop directory.') do |clean|
          config.clean = clean
        end

        opt.on('-x', '--xcodebuild-arguments arg1,arg2,…argN', Array,
               'Arguments to forward to xcodebuild') do |args|
          config.xcodebuild_arguments = args
        end

        opt.on('-a', '--author AUTHOR_NAME',
               'Name of author to attribute in docs (i.e. Realm)') do |a|
          config.author_name = a
        end

        opt.on('-u', '--author_url URL',
               'Author URL of this project (i.e. http://realm.io)') do |u|
          config.author_url = URI(u)
        end

        opt.on('-m', '--module MODULE_NAME',
               'Name of module being documented. (i.e. RealmSwift)') do |m|
          config.module_name = m
        end

        opt.on('-d', '--dash_url URL',
               'Location of the dash XML feed \
               (i.e. http://realm.io/docsets/realm.xml') do |d|
          config.dash_url = URI(d)
        end

        opt.on('-g', '--github_url URL',
               'GitHub URL of this project (i.e. \
                https://github.com/realm/realm-cocoa)') do |g|
          config.github_url = URI(g)
        end

        opt.on('--github-file-prefix PREFIX',
               'GitHub URL file prefix of this project (i.e. \
                https://github.com/realm/realm-cocoa/tree/v0.87.1)') do |g|
          config.github_file_prefix = g
        end

        opt.on('-s', '--sourcekitten-sourcefile FILEPATH',
               'XML doc file generated from sourcekitten to parse') do |s|
          config.sourcekitten_sourcefile = Pathname(s)
        end

        opt.on('-r', '--root-url URL',
               'Absolute URL root where these docs will be stored') do |r|
          config.root_url = URI(r)
          if !config.dash_url && config.root_url
            config.dash_url = URI.join(r, "docsets/#{config.module_name}.xml")
          end
        end

        opt.on('--module-version VERSION',
               'module version. will be used when generating docset') do |mv|
          config.version = mv
        end

        opt.on('--min-acl [private | internal | public]',
               'minimum access control level to document \
               (default is internal)') do |acl|
          if acl == 'private'
            config.min_acl = SourceDeclaration::AccessControlLevel.private
          elsif acl == 'public'
            config.min_acl = SourceDeclaration::AccessControlLevel.public
          end
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

    #-------------------------------------------------------------------------#

    # @!group Singleton

    # @return [Config] the current config instance creating one if needed.
    #
    def self.instance
      @instance ||= new
    end

    # Sets the current config instance. If set to nil the config will be
    # recreated when needed.
    #
    # @param  [Config, Nil] the instance.
    #
    # @return [void]
    #
    class << self
      attr_writer :instance
    end

    # Provides support for accessing the configuration instance in other
    # scopes.
    #
    module Mixin
      def config
        Config.instance
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
