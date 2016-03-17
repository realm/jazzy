require 'tmpdir'
require 'json'

module Jazzy
  class PodspecDocumenter
    attr_reader :podspec

    def initialize(podspec)
      @podspec = podspec
    end

    def sourcekitten_output
      sandbox = Pod::Sandbox.new(pod_config.sandbox_root)
      installer = Pod::Installer.new(sandbox, podfile)
      installer.install!
      stdout = Dir.chdir(sandbox.root) do
        pod_targets.map do |t|
          SourceKitten.run_sourcekitten(
            %W(doc --module-name #{podspec.module_name} -- -target #{t})
          )
        end
      end
      stdout.reduce([]) { |a, s| a + JSON.load(s) }.to_json
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
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    private

    # @!group Config helper methods

    def self.author_name(podspec)
      if podspec.authors.respond_to? :to_hash
        podspec.authors.keys.to_sentence || ''
      else
        if podspec.authors.respond_to? :to_ary
          podspec.authors.to_sentence
        else
          podspec.authors
        end
      end || ''
    end

    def self.github_file_prefix(podspec)
      return unless podspec.source[:url] =~ %r{github.com[:/]+(.+)/(.+)}
      org, repo = Regexp.last_match
      return unless org && repo
      repo.sub!(/\.git$/, '')
      return unless rev = podspec.source[:tag] || podspec.source[:commit]
      "https://github.com/#{org}/#{repo}/blob/#{rev}"
    end

    # @!group SourceKitten output helper methods

    attr_reader :pod_targets

    def pod_config
      Pod::Config.instance.tap do |c|
        c.installation_root = Pathname(Dir.mktmpdir)
        c.installation_root.rmtree if c.installation_root.exist?
        c.integrate_targets = false
        c.deduplicate_targets = false
        c.deterministic_uuids = false
      end
    end

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
      targets = (@pod_targets ||= [])
      @podfile ||= Pod::Podfile.new do
        platform :ios, '8.0'
        [podspec, *podspec.recursive_subspecs].each do |ss|
          ss.available_platforms.each do |p|
            # Travis builds take too long when building docs for all available
            # platforms for the Moya integration spec, so we just document OSX.
            # TODO: remove once jazzy is fast enough.
            next if ENV['JAZZY_INTEGRATION_SPECS'] &&
                    !p.to_s.start_with?('OS X')
            t = "Jazzy-#{ss.name.gsub('/', '__')}-#{p.name}"
            targets << "Pods-#{t}-#{ss.root.name}"
            target(t) do
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
