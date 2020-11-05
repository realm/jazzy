require 'set'
require 'jazzy/symbol_graph/graph'
require 'jazzy/symbol_graph/constraint'
require 'jazzy/symbol_graph/symbol'
require 'jazzy/symbol_graph/relationship'
require 'jazzy/symbol_graph/sym_node'
require 'jazzy/symbol_graph/ext_node'

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
          {
            filename =>
              Graph.new(File.read(filename), module_name).to_sourcekit,
          }
        end.to_json
      end
    end

    # Figure out the args to pass to symbolgraph-extract
    # rubocop:disable Metrics/CyclomaticComplexity
    def self.arguments(config, output_path)
      if config.module_name.empty?
        raise 'error: `--swift-build-tool symbolgraph` requires `--module`.'
      end

      user_args = config.build_tool_arguments.join

      if user_args =~ /--(?:module-name|minimum-access-level|output-dir)/
        raise 'error: `--build-tool-arguments` for '\
          "`--swift-build-tool symbolgraph` can't use `--module`, "\
          '`--minimum-access-level`, or `--output-dir`.'
      end

      # Default set
      args = [
        "--module-name=#{config.module_name}",
        '--minimum-access-level=private',
        "--output-dir=#{output_path}",
        '--skip-synthesized-members',
      ]

      # Things user can override
      args.append("--sdk=#{sdk(config)}") unless user_args =~ /--sdk/
      args.append("--target=#{target}") unless user_args =~ /--target/
      args.append("-F=#{config.source_directory}") unless user_args =~ /-F(?!s)/
      args.append("-I=#{config.source_directory}") unless user_args =~ /-I/

      args + config.build_tool_arguments
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Get the SDK path.  On !darwin this just isn't needed.
    def self.sdk(config)
      `xcrun --show-sdk-path --sdk #{config.sdk}`.chomp
    end

    # Guess a default LLVM target.  Feels like the tool should figure this
    # out from sdk + the binary somehow?
    def self.target
      `swift -version` =~ /Target: (.*?)$/
      Regexp.last_match[1] || 'x86_64-apple-macosx10.15'
    end

    # This is a last-ditch fallback for when symbolgraph doesn't
    # provide a name - at least conforming external types to local
    # protocols.
    def self.demangle(usr)
      args = %w[demangle -simplified -compact].append(usr.sub(/^s:/, 's'))
      output, = Executable.execute_command('swift', args, true)
      return output.chomp
    rescue
      usr
    end
  end
end
