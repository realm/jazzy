
# ------------------------------------ #
#  Jazzy Integration tests             #
# ------------------------------------ #

#-----------------------------------------------------------------------------#

# The following integrations tests are based on file comparison.
#
# 1.  For each test there is a folder with a `before` and `after` subfolders.
# 2.  The contents of the before folder are copied to the `TMP_DIR` folder and
#     then the given arguments are passed to the `JAZZY_BINARY`.
# 3.  After the jazzy command completes the execution the each file in the
#     `after` subfolder is compared to the contents of the temporary
#     directory.  If the contents of the file do not match an error is
#     registered.
#
# Notes:
#
# - The output of the jazzy command is saved in the `execution_output.txt` file
#   which should be added to the `after` folder to test the Jazzy UI.
# - To create a new test, just create a before folder with the environment to
#   test, copy it to the after folder and run the tested pod command inside.
#   Then just add the tests below this files with the name of the folder and
#   the arguments.
#
# Rationale:
#
# - Have a way to track precisely the evolution of the artifacts (and of the
#   UI) produced by jazzy (git diff of the after folders).
# - Allow uses to submit pull requests with the environment necessary to
#   reproduce an issue.
# - Have robust tests which don't depend on the programmatic interface of
#   Jazzy. These tests depend only the binary and its arguments an thus are
#   suitable for testing Jazzy regardless of the implementation (they could even
#   work for a Swift one)

#-----------------------------------------------------------------------------#

# @return [Pathname] The root of the repo.
#
ROOT = Pathname.new(File.expand_path('../../', __FILE__)) unless defined? ROOT
$:.unshift((ROOT + 'spec').to_s)

require 'rubygems'
require 'bundler/setup'
require 'pretty_bacon'
require 'colored'
require 'CLIntegracon'

require 'cocoapods'

def configure_cocoapods
  Pod::Config.instance.with_changes(silent: true) do
    config = Pod::Config.instance
    # working around a bug where `pod setup --silent` isn't silent
    if config.sources_manager.master_repo_functional?
      Pod::Command::Repo::Update.invoke(%w[master])
    else
      Pod::Command::Setup.invoke
    end
  end
end

CLIntegracon.configure do |c|
  c.spec_path = ROOT + 'spec/integration_specs'
  c.temp_path = ROOT + 'tmp'

  # Ignore certain OSX files
  c.ignores '.DS_Store'
  c.ignores '.git'
  c.ignores %r{^(?!((api-)?docs/|execution_output.txt))}
  c.ignores '*.tgz'

  # Remove absolute paths from output
  c.transform_produced '**/undocumented.json' do |path|
    File.write(
      path,
      File.read(path).gsub(
        (ROOT + 'tmp').to_s,
        '<TMP>',
      ),
    )
  end

  # Transform produced databases to csv
  c.transform_produced '**/*.dsidx' do |path|
    File.open("#{path}.csv", 'w') do |file|
      file.write `sqlite3 -header -csv #{path} "select * from searchIndex;"`
    end
  end
  # Now that we're comparing the CSV, we don't care about the binary
  c.ignores '**/*.dsidx'

  c.hook_into :bacon
end

describe_cli 'jazzy' do
  subject do |s|
    s.executable = "ruby #{ROOT + 'bin/jazzy'}"
    s.environment_vars = {
      'JAZZY_FAKE_DATE'            => 'YYYY-MM-DD',
      'JAZZY_FAKE_VERSION'         => 'X.X.X',
      'COCOAPODS_SKIP_UPDATE_MESSAGE' => 'TRUE',
      'JAZZY_INTEGRATION_SPECS' => 'TRUE',
    }
    s.default_args = []
    s.replace_path ROOT.to_s, 'ROOT'
    s.replace_pattern /^[\d\s:.-]+ ruby\[\d+:\d+\] warning:.*$[\n]?/, ''
    # Remove version numbers from CocoaPods dependencies
    # to make specs resilient against dependecy updates.
    s.replace_pattern(/(Installing \w+ )\((.*)\)/, '\1(X.Y.Z)')
  end

  require 'shellwords'
  realm_head = <<-HTML
<link rel="icon" href="https://realm.io/img/favicon.ico">
<link rel="apple-touch-icon-precomposed" sizes="57x57" href="https://realm.io/img/favicon-57x57.png" />
<link rel="apple-touch-icon-precomposed" sizes="114x114" href="https://realm.io/img/favicon-114x114.png" />
<link rel="apple-touch-icon-precomposed" sizes="72x72" href="https://realm.io/img/favicon-72x72.png" />
<link rel="apple-touch-icon-precomposed" sizes="144x144" href="https://realm.io/img/favicon-144x144.png" />
<link rel="apple-touch-icon-precomposed" sizes="120x120" href="https://realm.io/img/favicon-120x120.png" />
<link rel="apple-touch-icon-precomposed" sizes="152x152" href="https://realm.io/img/favicon-152x152.png" />
<link rel="icon" type="image/png" href="https://realm.io/img/favicon-32x32.png" sizes="32x32" />
<link rel="icon" type="image/png" href="https://realm.io/img/favicon-16x16.png" sizes="16x16" />
<script defer>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
  ga('create', 'UA-50247013-1', 'realm.io');
  ga('send', 'pageview');
</script>
  HTML

  spec_subset = ENV['JAZZY_SPEC_SUBSET']

  # rubocop:disable Style/MultilineIfModifier

  describe 'jazzy objective-c' do
    describe 'Creates Realm Objective-C docs' do
      realm_version = ''
      relative_path = 'spec/integration_specs/document_realm_objc/before'
      Dir.chdir(ROOT + relative_path) do
        realm_version = `./build.sh get-version`.chomp
        # jazzy will fail if it can't find all public header files
        `touch Realm/RLMPlatform.h`
      end
      behaves_like cli_spec 'document_realm_objc',
                            '--objc ' \
                            '--author Realm ' \
                            '--author_url "https://realm.io" ' \
                            '--github_url ' \
                            'https://github.com/realm/realm-cocoa ' \
                            '--github-file-prefix https://github.com/realm/' \
                            "realm-cocoa/tree/v#{realm_version} " \
                            '--module Realm ' \
                            "--module-version #{realm_version} " \
                            '--root-url https://realm.io/docs/objc/' \
                            "#{realm_version}/api/ " \
                            '--umbrella-header Realm/Realm.h ' \
                            '--framework-root . ' \
                            "--head #{realm_head.shellescape}"
    end

    describe 'Creates docs for ObjC project with a variety of contents' do
      behaves_like cli_spec 'misc_jazzy_objc_features',
                            '--theme fullwidth'
    end
  end if !spec_subset || spec_subset == 'objc'

  describe 'jazzy swift' do
    describe 'Creates docs with a module name, author name, project URL, ' \
      'xcodebuild options, and github info' do
      behaves_like cli_spec 'document_alamofire',
                            '-m Alamofire -a Alamofire ' \
                            '-u https://nshipster.com/alamofire ' \
                            '-x -project,Alamofire.xcodeproj ' \
                            '-g https://github.com/Alamofire/Alamofire ' \
                            '--github-file-prefix https://github.com/' \
                            'Alamofire/Alamofire/blob/4.3.0 ' \
                            '--module-version 4.3.0 ' \
                            '--root-url ' \
                            'https://static.realm.io/jazzy_demo/Alamofire/ ' \
                            '--skip-undocumented'
    end

    describe 'Creates Realm Swift docs' do
      realm_version = ''
      Dir.chdir(ROOT + 'spec/integration_specs/document_realm_swift/before') do
        realm_version = `./build.sh get-version`.chomp
      end
      behaves_like cli_spec 'document_realm_swift',
                            '--author Realm ' \
                            '--author_url "https://realm.io" ' \
                            '--github_url ' \
                            'https://github.com/realm/realm-cocoa ' \
                            '--github-file-prefix https://github.com/realm/' \
                            "realm-cocoa/tree/v#{realm_version} " \
                            '--module RealmSwift ' \
                            "--module-version #{realm_version} " \
                            '--root-url https://realm.io/docs/swift/' \
                            "#{realm_version}/api/ " \
                            '--xcodebuild-arguments ' \
                            '-scheme,RealmSwift ' \
                            "--head #{realm_head.shellescape}"
    end

    describe 'Creates Siesta docs' do
      behaves_like cli_spec 'document_siesta',
                            # Siesta already has Docs/
                            '--output api-docs',
                            # Use the default Swift version rather than the
                            # specified 4.0
                            '--swift-version='
    end

    describe 'Creates docs for Swift project with a variety of contents' do
      behaves_like cli_spec 'misc_jazzy_features'
    end
  end if !spec_subset || spec_subset == 'swift'

  describe 'jazzy cocoapods' do
    configure_cocoapods
    describe 'Creates docs for a podspec with dependencies and subspecs' do
      behaves_like cli_spec 'document_moya_podspec',
                            '--podspec=Moya.podspec'
    end
  end if !spec_subset || spec_subset == 'cocoapods'
end
