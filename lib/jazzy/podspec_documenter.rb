require 'tmpdir'
require 'json'

module Jazzy
  # rubocop:disable Metrics/ClassLength
  class PodspecDocumenter
    attr_reader :podspec

    def initialize(podspec)
      @podspec = podspec
    end

    # Build documentation from the given options
    # @param [Config] options
    def sourcekitten_output(config)
      installation_root = Pathname(Dir.mktmpdir(['jazzy', podspec.name]))
      installation_root.rmtree if installation_root.exist?
      Pod::Config.instance.with_changes(installation_root: installation_root,
                                        verbose: false) do
        sandbox = Pod::Sandbox.new(Pod::Config.instance.sandbox_root)
        installer = Pod::Installer.new(sandbox, podfile)
        installer.install!
        stdout = Dir.chdir(sandbox.root) do
          targets = installer.pod_targets
                             .select { |pt| pt.pod_name == podspec.root.name }
                             .map(&:label)

          targets.map do |t|
            args = %W[doc --module-name #{podspec.module_name} -- -target #{t}]
            swift_version = (config.swift_version || '4')[0] + '.0'
            args << "SWIFT_VERSION=#{swift_version}"
            SourceKitten.run_sourcekitten(args)
          end
        end
        stdout.reduce([]) { |a, s| a + JSON.parse(s) }.to_json
      end
    end

    def self.create_podspec(podspec_path)
      case podspec_path
      when Pathname, String
        require 'cocoapods'
        Pod::Specification.from_file(podspec_path)
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.apply_config_defaults(podspec, config)
      return unless podspec

      unless config.author_name_configured
        config.author_name = author_name(podspec)
      end
      unless config.module_name_configured
        config.module_name = podspec.module_name
      end
      unless config.author_url_configured
        config.author_url = podspec.homepage || github_file_prefix(podspec)
      end
      unless config.version_configured
        config.version = podspec.version.to_s
      end
      unless config.github_file_prefix_configured
        config.github_file_prefix = github_file_prefix(podspec)
      end
      unless config.swift_version_configured
        trunk_swift_build = podspec.attributes_hash['pushed_with_swift_version']
        config.swift_version = trunk_swift_build if trunk_swift_build
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    private

    # @!group Config helper methods

    def self.author_name(podspec)
      if podspec.authors.respond_to? :to_hash
        podspec.authors.keys.to_sentence || ''
      elsif podspec.authors.respond_to? :to_ary
        podspec.authors.to_sentence
      end || podspec.authors || ''
    end

    private_class_method :author_name

    def self.github_file_prefix(podspec)
      return unless podspec.source[:url] =~ %r{github.com[:/]+(.+)/(.+)}
      org, repo = Regexp.last_match
      return unless org && repo
      repo.sub!(/\.git$/, '')
      return unless rev = podspec.source[:tag] || podspec.source[:commit]
      "https://github.com/#{org}/#{repo}/blob/#{rev}"
    end

    private_class_method :github_file_prefix

    # @!group SourceKitten output helper methods

    def pod_path
      if podspec.defined_in_file
        podspec.defined_in_file.parent
      else
        config.source_directory
      end
    end

    def podfile
      podspec = @podspec
      path = pod_path
      @podfile ||= Pod::Podfile.new do
        install! 'cocoapods',
                 integrate_targets: false,
                 deterministic_uuids: false

        [podspec, *podspec.recursive_subspecs].each do |ss|
          # test_specification exists from CocoaPods 1.3.0
          next if ss.respond_to?('test_specification') && ss.test_specification

          ss.available_platforms.each do |p|
            # Travis builds take too long when building docs for all available
            # platforms for the Moya integration spec, so we just document OSX.
            # Also Moya's RxSwift subspec doesn't yet support Swift 4, so skip
            # that too while we're at it.
            # TODO: remove once jazzy is fast enough.
            if ENV['JAZZY_INTEGRATION_SPECS']
              next if (p.name != :osx) || (ss.name == 'Moya/RxSwift')
            end
            target("Jazzy-#{ss.name.gsub('/', '__')}-#{p.name}") do
              use_frameworks!
              platform p.name, p.deployment_target
              pod ss.name, path: path.realpath.to_s
            end
          end
        end
      end
    end
  end
end
