require 'jazzy/symbol_graph/graph'
require 'jazzy/symbol_graph/constraint'
require 'jazzy/symbol_graph/symbol'
require 'jazzy/symbol_graph/relationship'

# This is the top-level symbolgraph driver that deals with
# figuring out arguments, running the tool, and loading the
# results.

module Jazzy
  module SymbolGraph
    # Run `swift symbolgraph-extract` with configured args,
    # parse the results, and return as JSON in SourceKit[ten]
    # format.
    def self.build(config)
      Dir.mktmpdir do |tmp_dir|
        args = arguments(config, tmp_dir)

        Executable.execute_command('swift',
                                   args.unshift('symbolgraph-extract'),
                                   true) # raise on error

        Dir[tmp_dir + '/*.symbols.json'].map do |filename|
          # The @ part is for extensions in our module (before the @)
          # of types in another module (after the @).
          filename =~ /(.*?)(@(.*?))?\.symbols/
          module_name = Regexp.last_match[3] || Regexp.last_match[1]
          Graph.new(File.read(filename), module_name).to_sourcekitten_hash
        end.compact.to_json
      end
    end

    # Figure out the args to pass to symbolgraph-extract
    # rubocop:disable Metrics/MethodLength
    def self.arguments(config, output_path)
      if config.module_name.empty?
        raise 'error: `--swift-build-tool symbolgraph` requires `--module`.'
      end

      # Default set
      [
        "--module-name=#{config.module_name}",
        '--minimum-access-level=private',
        "--output-dir=#{output_path}",
      ] +
        # Overridable set
        if config.build_tool_arguments.empty?
          [
            "--sdk=#{sdk(config)}",
            "--target=#{target}",
            '--skip-synthesized-members',
            "-F=#{config.source_directory}",
            "-I=#{config.source_directory}",
          ]
        else
          forbidden = config.build_tool_arguments &
                      ['--module', '--minimum-access-level', '--output-dir']
          unless forbidden.empty?
            raise 'error: `--build-tool-arguments` for '\
              "`--swift-build-tool symbolgraph` can't use `--module`, "\
              '`--minimum-access-level`, or `--output-dir`.'
          end
          config.build_tool_arguments
        end
    end
    # rubocop:enable Metrics/MethodLength

    # Get the SDK path.  Not sure what the Linux version is.
    def self.sdk(config)
      `xcrun --show-sdk-path --sdk #{config.sdk}`.chomp
    end

    # Guess a default LLVM target.  Tool failure that it needs this.
    def self.target
      `swift -version` =~ /Target: (.*?)$/
      Regexp.last_match[1] || 'x86_64-apple-macosx10.15'
    end
  end
end
