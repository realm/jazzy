require 'tmpdir'
require 'json'

module Jazzy
  class PodspecDocumenter
    attr_reader :podspec

    def initialize(podspec)
      @podspec = podspec
    end

    def sourcekitten_output
      pod_config = Pod::Config.instance
      pod_config.installation_root = Pathname(Dir.mktmpdir) # Pathname.pwd + 'jazzy'
      pod_config.installation_root.rmtree if pod_config.installation_root.exist?
      pod_config.integrate_targets = false
      pod_path = podspec.defined_in_file.parent rescue config.source_directory
      pod_targets = []
      podspec = @podspec
      podfile = Pod::Podfile.new do
        platform :ios, '8.0'
        [podspec, *podspec.recursive_subspecs].each do |ss|
          ss.available_platforms.each do |p|
            t = "Jazzy-#{ss.name.gsub(/\//, '__')}-#{p.name}"
            pod_targets << "Pods-#{t}-#{ss.root.name}"
            target(t) do
              use_frameworks!
              platform p.name, p.deployment_target
              pod ss.name, path: pod_path.realpath.to_s
            end
          end
        end
      end
      sandbox = Pod::Sandbox.new(pod_config.sandbox_root)
      installer = Pod::Installer.new(sandbox, podfile)
      installer.install!
      stdout = Dir.chdir(sandbox.root) do
        pod_targets.map do |t|
          SourceKitten.run_sourcekitten(
            %W(doc --module-name #{podspec.module_name} -target #{t})
          )
        end
      end
      stdout.reduce([]) { |a, s| a + JSON.load(s) }.to_json
    end

    def self.configure(config, podspec)
      case podspec
      when Pathname, String
        require 'cocoapods'
        podspec = Pod::Specification.from_file(podspec)
      end

      return unless podspec

      config.author_name =
        if podspec.authors.respond_to? :to_hash
          podspec.authors.keys.join(' ') || ''
        else
          if podspec.authors.respond_to? :to_ary
            podspec.authors.join(' ')
          else
            podspec.authors
          end
        end || ''

      config.module_name = podspec.module_name
      config.author_url = podspec.homepage || ''

      config.version = podspec.version.to_s

      if url = podspec.source[:url]
        if url =~ %r{github.com[:/]+(.+)/(.+)}
          org, repo = Regexp.last_match
          if org && repo
            repo.sub!(/\.git$/, '')
            if rev = podspec.source[:tag] || podspec.source[:commit]
              config.github_file_prefix = "https://github.com/#{org}/#{repo}/blob/#{rev}"
            end
          end
        end
      end

      podspec
    end
  end
end
