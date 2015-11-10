require 'optparse'
require 'pathname'
require 'uri'

require 'jazzy/doc'
require 'jazzy/podspec_documenter'
require 'jazzy/source_declaration/access_control_level'

module Jazzy
  # rubocop:disable Metrics/ClassLength
  class Config
    # rubocop:disable Style/AccessorMethodName
    class Attribute
      attr_reader :name, :description, :command_line, :default, :parse

      def initialize(name, description: nil, command_line: nil,
                     default: nil, parse: ->(x) { x })
        @name = name
        @description = Array(description)
        @command_line = Array(command_line)
        @default = default
        @parse = parse
      end

      def get(config)
        config.method(name).call
      end

      def set_raw(config, val)
        config.method("#{name}=").call(val)
      end

      def set(config, val, mark_configured: true)
        set_raw(config, parse.call(val))
        config.method("#{name}_configured=").call(true) if mark_configured
      end

      def set_to_default(config)
        set(config, default, mark_configured: false) if default
      end

      def set_if_unconfigured(config, val)
        set(config, val) unless configured?(config)
      end

      def configured?(config)
        config.method("#{name}_configured").call
      end

      def attach_to_option_parser(config, opt)
        return if command_line.empty?
        opt.on(*command_line, *description) do |val|
          set(config, val)
        end
      end
    end
    # rubocop:enable Style/AccessorMethodName

    def self.config_attr(name, **opts)
      attr_accessor name
      attr_accessor "#{name}_configured"
      @all_config_attrs ||= []
      @all_config_attrs << Attribute.new(name, **opts)
    end

    class << self
      attr_reader :all_config_attrs
    end

    # ──────── Build ────────

    # rubocop:disable Style/AlignParameters

    config_attr :output,
      description: 'Folder to output the HTML docs to',
      command_line: ['-o', '--output FOLDER'],
      default: 'docs',
      parse: ->(o) { Pathname(o) }

    config_attr :clean,
      command_line: ['-c', '--[no-]clean'],
      description: ['Delete contents of output directory before running. ',
                    'WARNING: If --output is set to ~/Desktop, this will '\
                    'delete the ~/Desktop directory.'],
      default: false

    config_attr :objc_mode,
      command_line: '--[no-]objc',
      description: 'Generate docs for Objective-C.',
      default: false

    config_attr :umbrella_header,
      command_line: '--umbrella-header PATH',
      description: 'Umbrella header for your Objective-C framework.',
      parse: ->(uh) { Pathname(uh) }

    config_attr :framework_root,
      command_line: '--framework-root PATH',
      description: 'The root path to your Objective-C framework.',
      parse: ->(fr) { Pathname(fr) }

    config_attr :config_file,
      command_line: '--config PATH',
      description: ['Configuration file (.yaml or .json)',
                    'Default: .jazzy.yaml in source directory or ancestor'],
      parse: ->(cf) { Pathname(cf) }

    config_attr :xcodebuild_arguments,
      command_line: ['-x', '--xcodebuild-arguments arg1,arg2,…argN', Array],
      description: 'Arguments to forward to xcodebuild',
      default: []

    config_attr :sourcekitten_sourcefile,
      command_line: ['-s', '--sourcekitten-sourcefile FILEPATH'],
      description: 'File generated from sourcekitten output to parse',
      parse: ->(s) { Pathname(s) }

    config_attr :source_directory,
      command_line: '--source-directory DIRPATH',
      description: 'The directory that contains the source to be documented',
      default: Pathname.pwd,
      parse: ->(sd) { Pathname(sd) }

    config_attr :excluded_files,
      command_line: ['-e', '--exclude file1,file2,…fileN', Array],
      description: 'Files to be excluded from documentation',
      default: [],
      parse: ->(files) do
        files.map { |f| File.expand_path(f) }
      end

    config_attr :swift_version,
      command_line: '--swift-version VERSION',
      default: '2.1'

    # ──────── Metadata ────────

    config_attr :author_name,
      command_line: ['-a', '--author AUTHOR_NAME'],
      description: 'Name of author to attribute in docs (e.g. Realm)',
      default: ''

    config_attr :author_url,
      command_line: ['-u', '--author_url URL'],
      description: 'Author URL of this project (e.g. http://realm.io)',
      default: '',
      parse: ->(u) { URI(u) }

    config_attr :module_name,
      command_line: ['-m', '--module MODULE_NAME'],
      description: 'Name of module being documented. (e.g. RealmSwift)',
      default: ''

    config_attr :version,
      command_line: '--module-version VERSION',
      description: 'module version. will be used when generating docset',
      default: '1.0'

    config_attr :copyright,
      command_line: '--copyright COPYRIGHT_MARKDOWN',
      description: 'copyright markdown rendered at the bottom of the docs pages'

    config_attr :readme_path,
      command_line: '--readme FILEPATH',
      description: 'The path to a markdown README file',
      parse: ->(rp) { Pathname(rp) }

    config_attr :podspec,
      command_line: '--podspec FILEPATH',
      parse: ->(ps) { PodspecDocumenter.create_podspec(Pathname(ps)) if ps },
      default: Dir['*.podspec{,.json}'].first

    config_attr :docset_platform, default: 'jazzy'

    config_attr :docset_icon,
      command_line: '--docset-icon FILEPATH',
      parse: ->(di) { Pathname(di) }

    config_attr :docset_path,
      command_line: '--docset-path DIRPATH',
      description: 'The relative path for the generated docset'

    # ──────── URLs ────────

    config_attr :root_url,
      command_line: ['-r', '--root-url URL'],
      description: 'Absolute URL root where these docs will be stored',
      parse: ->(r) { URI(r) }

    config_attr :dash_url,
      command_line: ['-d', '--dash_url URL'],
      description: 'Location of the dash XML feed '\
                    'e.g. http://realm.io/docsets/realm.xml)',
      parse: ->(d) { URI(d) }

    config_attr :github_url,
      command_line: ['-g', '--github_url URL'],
      description: 'GitHub URL of this project (e.g. '\
                   'https://github.com/realm/realm-cocoa)',
      parse: ->(g) { URI(g) }

    config_attr :github_file_prefix,
      command_line: '--github-file-prefix PREFIX',
      description: 'GitHub URL file prefix of this project (e.g. '\
                   'https://github.com/realm/realm-cocoa/tree/v0.87.1)'

    # ──────── Doc generation options ────────

    config_attr :min_acl,
      command_line: '--min-acl [private | internal | public]',
      description: 'minimum access control level to document',
      default: 'public',
      parse: ->(acl) do
        SourceDeclaration::AccessControlLevel.from_human_string(acl)
      end

    config_attr :skip_undocumented,
      command_line: '--[no-]skip-undocumented',
      description: "Don't document declarations that have no documentation '\
                  'comments.",
      default: false

    config_attr :hide_documentation_coverage,
      command_line: '--[no-]hide-documentation-coverage',
      description: "Hide \"(X\% documented)\" from the generated documents",
      default: false

    config_attr :custom_categories,
      description: ['Custom navigation categories to replace the standard '\
                    '“Classes, Protocols, etc.”', 'Types not explicitly named '\
                    'in a custom category appear in generic groups at the end.',
                    'Example: http://git.io/vcTZm'],
      default: []

    config_attr :template_directory,
      command_line: ['-t', '--template-directory DIRPATH'],
      description: 'The directory that contains the mustache templates to use',
      default: Pathname(__FILE__).parent + 'templates',
      parse: ->(td) { Pathname(td) }

    config_attr :assets_directory,
      command_line: '--assets-directory DIRPATH',
      description: 'The directory that contains the assets (CSS, JS, images) '\
                   'used by the templates',
      default: Pathname(__FILE__).parent + 'assets',
      parse: ->(ad) { Pathname(ad) }

    # rubocop:enable Style/AlignParameters

    def initialize
      self.class.all_config_attrs.each do |attr|
        attr.set_to_default(self)
      end
    end

    def template_directory=(template_directory)
      @template_directory = template_directory
      Doc.template_path = template_directory
    end

    # rubocop:disable Metrics/MethodLength
    def self.parse!
      config = new
      config.parse_command_line
      config.parse_config_file
      PodspecDocumenter.apply_config_defaults(config.podspec, config)

      if config.root_url
        config.dash_url ||= URI.join(
          config.root_url,
          "docsets/#{config.module_name}.xml")
      end

      config
    end

    def parse_command_line
      OptionParser.new do |opt|
        opt.banner = 'Usage: jazzy'
        opt.separator ''
        opt.separator 'Options'

        self.class.all_config_attrs.each do |attr|
          attr.attach_to_option_parser(self, opt)
        end

        opt.on('-v', '--version', 'Print version number') do
          puts 'jazzy version: ' + Jazzy::VERSION
          exit
        end

        opt.on('-h', '--help [TOPIC]', 'Available topics:',
               '  usage   Command line options (this help message)',
               '  config  Configuration file options',
               '...or an option keyword, e.g. "dash"') do |topic|
          case topic
          when 'usage', nil
            puts opt
          when 'config'
            print_config_file_help
          else
            print_option_help(topic)
          end
          exit
        end
      end.parse!

      expand_paths(Pathname.pwd)
    end

    def parse_config_file
      config_path = locate_config_file
      return unless config_path

      puts "Using config file #{config_path}"
      config_file = read_config_file(config_path)
      self.class.all_config_attrs.each do |attr|
        key = attr.name.to_s
        if config_file.key?(key)
          attr.set_if_unconfigured(self, config_file[key])
        end
      end

      expand_paths(config_path.parent)
    end

    def locate_config_file
      return config_file if config_file

      source_directory.ascend do |dir|
        candidate = dir.join('.jazzy.yaml')
        return candidate if candidate.exist?
      end

      nil
    end

    def read_config_file(file)
      case File.extname(file)
        when '.json'         then JSON.parse(File.read(file))
        when '.yaml', '.yml' then YAML.load(File.read(file))
        else raise "Config file must be .yaml or .json, but got #{file.inspect}"
      end
    end

    def expand_paths(base_path)
      self.class.all_config_attrs.each do |attr|
        val = attr.get(self)
        if val.respond_to?(:expand_path)
          attr.set_raw(self, val.expand_path(base_path))
        end
      end
    end

    def print_config_file_help
      puts <<-_EOS_

        By default, jazzy looks for a file named ".jazzy.yaml" in the source
        directory and its ancestors. You can override the config file location
        with --config.

        (The source directory is the current working directory by default.
        You can override that with --source-directory.)

        The config file can be in YAML or JSON format. Available options are:

        _EOS_
        .gsub(/^ +/, '')

      print_option_help
    end

    def print_option_help(topic = '')
      found = false
      self.class.all_config_attrs.each do |attr|
        match = ([attr.name] + attr.command_line).any? do
          |opt| opt.to_s.include?(topic)
        end
        if match
          found = true
          puts
          puts attr.name.to_s.gsub('_', ' ').upcase
          puts
          puts "  Config file:   #{attr.name}"
          cmd_line_forms = attr.command_line.select { |opt| opt.is_a?(String) }
          if cmd_line_forms.any?
            puts "  Command line:  #{cmd_line_forms.join(', ')}"
          end
          puts
          print_attr_description(attr)
        end
      end
      warn "Unknown help topic #{topic.inspect}" unless found
    end

    def print_attr_description(attr)
      attr.description.each { |line| puts "  #{line}" }
      if attr.default && attr.default != ''
        puts "  Default: #{attr.default}"
      end
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
